module PostemsSyncBulkInsert
  COLUMNS = %w[QuarterNumberEvent Hash RecordInfo Information Created SourceInfo PostemFlags].freeze

  def self.insert_batch!(records)
    return if records.empty?

    if Postem.respond_to?(:insert_all)
      Postem.insert_all(records)
      return
    end

    conn = Postem.connection
    table = conn.quote_table_name(Postem.table_name)
    col_sql = COLUMNS.map { |c| conn.quote_column_name(c) }.join(', ')
    tuples = records.map do |r|
      vals = COLUMNS.map do |col|
        v = r[col]
        case col
        when 'QuarterNumberEvent', 'PostemFlags'
          v.nil? ? 'NULL' : v.to_i.to_s
        when 'Created'
          v.nil? ? 'NULL' : conn.quote(v)
        else
          v.nil? ? 'NULL' : conn.quote(v)
        end
      end
      "(#{vals.join(', ')})"
    end
    sql = "INSERT INTO #{table} (#{col_sql}) VALUES #{tuples.join(', ')}"
    conn.execute(sql)
  end
end

# Sync Postems table across production servers.
#
# Use when the 4 production servers have drifted and you want one canonical copy
# on all of them. Tuned for large tables (~500k+ rows).
#
# Monthly DB recreation (Server 1): FreeBMD1 creates a new database each month and
# recreates the Postems table. CopyPostems.pl copies postems from current_db to
# next_db; AlignPostems.pl replays entries from postemlog written after #logstart.
# MyopicVicar must write to the same postemlog (config.postem_log_path or ENV['POSTEMLOG'])
# when creating postems so that postems created during the update window are not lost.
#
# Workflow:
#   1. On the server you treat as source of truth:
#        rake postems:export FILE=/tmp/postems.csv
#   2. Compress for transfer (saves bandwidth; file will be ~200-400 MB uncompressed):
#        gzip -k /tmp/postems.csv   # -> /tmp/postems.csv.gz
#   3. Copy to other servers (e.g. scp postems.csv.gz). Decompress there if needed.
#   4. On each other server:
#        rake postems:sync_from_file FILE=/path/to/postems.csv
#
# sync_from_file streams the CSV (no full load into memory), preloads existing
# (Hash, Information) from the DB, and batch-inserts missing rows.
# Compatible with Rails 5.1 (uses create! in batches when insert_all is not available).
#
namespace :postems do
  EXPORT_COLUMNS = %w[PostemID QuarterNumberEvent Hash RecordInfo Information Created SourceInfo PostemFlags].freeze
  BATCH_SIZE = 2000

  desc "Export all Postems from the current FreeBMD DB to CSV. FILE=path (default: postems_export.csv)"
  task export: :environment do
    require 'csv'
    file = ENV.fetch('FILE', Rails.root.join('postems_export.csv').to_s)
    count = 0

    File.open(file, 'w') do |out|
      out.puts CSV.generate_line(EXPORT_COLUMNS)
      Postem.unscoped.each do |p|
        row = EXPORT_COLUMNS.map { |col| p[col] }
        out.puts CSV.generate_line(row)
        count += 1
      end
    end

    puts "Exported #{count} postems to #{file}"
  end

  task sync_from_file: :environment do
    file = ENV['FILE']
    raise "FILE=path required. Example: rake postems:sync_from_file FILE=/tmp/postems.csv" if file.blank?
    raise "File not found: #{file}" unless File.file?(file)

    require 'csv'

    puts "Loading existing (Hash, Information) from DB..."
    existing = Set.new
    Postem.unscoped.select(:Hash, :Information).each do |p|
      existing.add([p['Hash'].to_s, p['Information'].to_s.strip].freeze)
    end
    puts "  #{existing.size} existing postems in target DB."

    inserted = 0
    skipped = 0
    batch = []
    io = file.end_with?('.gz') ? Zlib::GzipReader.open(file) : File.open(file, 'r')

    # Do not append synced postems to postemlog (they are bulk copies, not new user submissions).
    # Only set if Postem model has been updated (deploy rake + app/models/freebmd/postem.rb together for prod).
    postemlog_skip_was_set = Postem.respond_to?(:skip_postemlog_for_sync=)
    Postem.skip_postemlog_for_sync = true if postemlog_skip_was_set

    begin
      csv = CSV.new(io, headers: true)
      headers = csv.readline.headers
      unless (EXPORT_COLUMNS - headers).empty?
        puts "Warning: expected columns #{EXPORT_COLUMNS.join(', ')}; got #{headers.join(', ')}"
      end

      csv.each do |row|
        hash_val = row['Hash'].to_s
        info_val = row['Information'].to_s.strip

        if hash_val.blank? || info_val.blank?
          skipped += 1
          next
        end
        if existing.include?([hash_val, info_val])
          skipped += 1
          next
        end

        batch << {
          'QuarterNumberEvent' => row['QuarterNumberEvent'].to_i,
          'Hash' => hash_val,
          'RecordInfo' => (row['RecordInfo'].to_s[0, 250]).presence,
          'Information' => row['Information'].to_s[0, 250],
          'Created' => row['Created'].presence,
          'SourceInfo' => (row['SourceInfo'].to_s[0, 250]).presence,
          'PostemFlags' => (row['PostemFlags'].presence || 0).to_i
        }
        existing.add([hash_val, info_val].freeze)

        if batch.size >= BATCH_SIZE
          PostemsSyncBulkInsert.insert_batch!(batch)
          inserted += batch.size
          print "\r  Inserted #{inserted}, skipped #{skipped}..."
          batch = []
        end
      end

      if batch.any?
        PostemsSyncBulkInsert.insert_batch!(batch)
        inserted += batch.size
      end
    ensure
      io.close
      Postem.skip_postemlog_for_sync = false if postemlog_skip_was_set
    end

    puts "\nSync complete: #{inserted} inserted, #{skipped} skipped (already present)."
  end

  desc "Insert Postems from CSV that don't already exist (by Hash + Information). FILE=path required. Streams file and batch-inserts."
  task sync_from_file_old: :environment do
    file = ENV['FILE']
    raise "FILE=path required. Example: rake postems:sync_from_file FILE=/tmp/postems.csv" if file.blank?
    raise "File not found: #{file}" unless File.file?(file)

    require 'csv'

    puts "Loading existing (Hash, Information) from DB..."
    existing = Set.new
    Postem.unscoped.select(:Hash, :Information).each do |p|
      existing.add([p['Hash'].to_s, p['Information'].to_s.strip].freeze)
    end
    puts "  #{existing.size} existing postems in target DB."

    # Rails 6+ insert_all is much faster; Rails 5 falls back to batched create!
    insert_batch = lambda do |records|
      if Postem.respond_to?(:insert_all)
        Postem.insert_all(records)
      else
        records.each { |r| Postem.unscoped.create!(r) }
      end
    end

    inserted = 0
    skipped = 0
    batch = []
    io = file.end_with?('.gz') ? Zlib::GzipReader.open(file) : File.open(file, 'r')

    # Do not append synced postems to postemlog (they are bulk copies, not new user submissions).
    # Only set if Postem model has been updated (deploy rake + app/models/freebmd/postem.rb together for prod).
    postemlog_skip_was_set = Postem.respond_to?(:skip_postemlog_for_sync=)
    Postem.skip_postemlog_for_sync = true if postemlog_skip_was_set

    begin
      csv = CSV.new(io, headers: true)
      headers = csv.readline.headers
      unless (EXPORT_COLUMNS - headers).empty?
        puts "Warning: expected columns #{EXPORT_COLUMNS.join(', ')}; got #{headers.join(', ')}"
      end

      csv.each do |row|
        hash_val = row['Hash'].to_s
        info_val = row['Information'].to_s.strip

        if hash_val.blank? || info_val.blank?
          skipped += 1
          next
        end
        if existing.include?([hash_val, info_val])
          skipped += 1
          next
        end

        batch << {
          'QuarterNumberEvent' => row['QuarterNumberEvent'].to_i,
          'Hash' => hash_val,
          'RecordInfo' => (row['RecordInfo'].to_s[0, 250]).presence,
          'Information' => row['Information'].to_s[0, 250],
          'Created' => row['Created'].presence,
          'SourceInfo' => (row['SourceInfo'].to_s[0, 250]).presence,
          'PostemFlags' => (row['PostemFlags'].presence || 0).to_i
        }
        existing.add([hash_val, info_val].freeze)

        if batch.size >= BATCH_SIZE
          insert_batch.call(batch)
          inserted += batch.size
          print "\r  Inserted #{inserted}, skipped #{skipped}..."
          batch = []
        end
      end

      if batch.any?
        insert_batch.call(batch)
        inserted += batch.size
      end
    ensure
      io.close
      Postem.skip_postemlog_for_sync = false if postemlog_skip_was_set
    end

    puts "\nSync complete: #{inserted} inserted, #{skipped} skipped (already present)."
  end

   desc "Set EntryPostem on BestGuess/BestGuessMarriages from Postems. DRY_RUN=1 = counts only. POSTEM_FLAG_HASH_BATCH=300 (50–2000)."
  task set_entry_postem_flags_old: :environment do
    dry = ENV['DRY_RUN'].present?
    bit = BestGuess::ENTRY_POSTEM
    batch_size = (ENV['POSTEM_FLAG_HASH_BATCH'] || '300').to_i.clamp(50, 2000)
    flag_models = [BestGuess, BestGuessMarriage]

    puts "=== postems:set_entry_postem_flags #{dry ? '(DRY RUN — no UPDATE)' : ''} ==="
    puts "Database: #{BestGuess.connection.current_database}"
    puts

    # Step 1–2: Postems (AR)
    postems_row_count = Postem.unscoped.count
    puts "Step 1 — Postems: #{postems_row_count} row(s) in table"

    hashes = Postem.unscoped.where.not(Hash: [nil, '']).distinct.pluck(:Hash)
    puts "Step 2 — Distinct Hash from Postems: #{hashes.size}"
    if hashes.empty?
      puts "Nothing to do."
      next
    end

    # Step 3: BestGuessHash stats (AR; huge `hashes` → large IN (...) — watch max_allowed_packet)
    linked_record_numbers = BestGuessHash.where(Hash: hashes).distinct.count(:RecordNumber)
    hashes_with_row = BestGuessHash.where(Hash: hashes).distinct.pluck(:Hash)
    orphan_hash_count = (hashes - hashes_with_row).size
    puts "Step 3 — BestGuessHash: #{linked_record_numbers} distinct RecordNumber(s) linked to those hashes"
    puts "         (Postems hashes with no BestGuessHash row: #{orphan_hash_count} distinct Hash — flags cannot be set for those)"
    puts

    # Step 4–5: Hash batch → RecordNumber via BestGuessHash, then BestGuess / BestGuessMarriages by RecordNumber.
    # Same rows as JOIN would touch: BGH is the canonical Hash → RecordNumber map. No JOIN needed on the flag table;
    # WHERE RecordNumber IN (?) often uses the primary key / index cleanly.
    puts "Step 4–5 — Rows where Confirmed is missing EntryPostem (#{bit}):"
    would_by_table = {}
    flag_models.each do |model|
      table_name = model.table_name
      would_total = 0
      hashes.each_slice(batch_size) do |batch|
        record_numbers = BestGuessHash.where(Hash: batch).distinct.pluck(:RecordNumber)
        next if record_numbers.empty?

        would_total += model.unscoped
          .where(RecordNumber: record_numbers)
          .where("(#{table_name}.Confirmed & ?) = 0", bit)
          .count
      end
      would_by_table[table_name] = would_total
      puts "         #{table_name}: #{would_total}"
    end
    puts

    if dry
      puts "DRY RUN finished (no UPDATE executed)."
      next
    end

    if would_by_table.values.sum.zero?
      puts "All relevant rows already have EntryPostem; nothing to update."
      next
    end

    puts "Applying UPDATEs (batched by Hash)…"
    flag_models.each do |model|
      table_name = model.table_name
      batches = 0
      hashes.each_slice(batch_size) do |batch|
        record_numbers = BestGuessHash.where(Hash: batch).distinct.pluck(:RecordNumber)
        if record_numbers.any?
          model.unscoped
            .where(RecordNumber: record_numbers)
            .where("(#{table_name}.Confirmed & ?) = 0", bit)
            .update_all("Confirmed = Confirmed | #{bit.to_i}")
        end
        batches += 1
        print "\r  #{table_name}: batch #{batches}..." if (batches % 10).zero?
      end
      puts "\r  #{table_name}: done (#{batches} batch(es))."
    end
    puts "Finished."
  end

   desc "Set EntryPostem from Postems (streaming + batched SQL). DRY_RUN=1 = counts only. POSTEM_FLAG_HASH_BATCH=300, POSTEMS_FLAG_ROW_BATCH=3000."
  task set_entry_postem_flags: :environment do
    dry = ENV['DRY_RUN'].present?
    bit = BestGuess::ENTRY_POSTEM
    hash_batch = (ENV['POSTEM_FLAG_HASH_BATCH'] || '300').to_i.clamp(50, 2000)
    row_batch = (ENV['POSTEMS_FLAG_ROW_BATCH'] || '3000').to_i.clamp(500, 20_000)
    flag_models = [BestGuess, BestGuessMarriage]
    conn = Postem.connection

    puts "=== postems:set_entry_postem_flags #{dry ? '(DRY RUN — no UPDATE)' : ''} ==="
    puts "Database: #{conn.current_database}"
    puts

    postems_row_count = Postem.unscoped.count
    puts "Step 1 — Postems: #{postems_row_count} row(s)"

    distinct_hash_count = Postem.unscoped.where.not(Hash: [nil, '']).distinct.count(:Hash)
    puts "Step 2 — Distinct Hash (SQL count, not loaded into memory): #{distinct_hash_count}"
    if distinct_hash_count.zero?
      puts "Nothing to do."
      next
    end

    # Step 3: single aggregate queries — no giant Ruby array of hashes
    linked_sql = <<-SQL.squish
      SELECT COUNT(DISTINCT h.RecordNumber) FROM BestGuessHash h
      INNER JOIN (SELECT DISTINCT `Hash` FROM Postems WHERE `Hash` IS NOT NULL AND `Hash` != '') p
      ON p.Hash = h.Hash
    SQL
    orphan_sql = <<-SQL.squish
      SELECT COUNT(DISTINCT p.`Hash`) FROM Postems p
      LEFT JOIN BestGuessHash h ON h.Hash = p.Hash
      WHERE p.`Hash` IS NOT NULL AND p.`Hash` != '' AND h.`Hash` IS NULL
    SQL
    linked_rn_count = conn.select_value(linked_sql).to_i
    orphan_hash_count = conn.select_value(orphan_sql).to_i
    puts "Step 3 — BestGuessHash: #{linked_rn_count} distinct RecordNumber(s) linked to postem hashes"
    puts "         Postems Hash with no BestGuessHash row: #{orphan_hash_count} (cannot set flag)"
    puts

    puts "Step 4–5 — #{dry ? 'Count' : 'Update'} (single pass over Postems by PostemID, batched Hash IN):"
    would_by_table = { BestGuess.table_name => 0, BestGuessMarriage.table_name => 0 }
    seen_rn = { BestGuess.table_name => Set.new, BestGuessMarriage.table_name => Set.new } if dry

    last_id = 0
    chunk_idx = 0
    update_slices = 0
    loop do
      rows = Postem.unscoped.where.not(Hash: [nil, ''])
        .where('PostemID > ?', last_id)
        .order(:PostemID)
        .limit(row_batch)
        .pluck(:PostemID, :Hash)
      break if rows.empty?

      last_id = rows.last.first
      chunk_idx += 1
      rows.map { |_, h| h }.uniq.reject(&:blank?).each_slice(hash_batch) do |slice|
        record_numbers = BestGuessHash.where(Hash: slice).distinct.pluck(:RecordNumber)
        next if record_numbers.empty?

        flag_models.each do |model|
          table_name = model.table_name
          if dry
            fresh_rns = record_numbers.reject { |rn| seen_rn[table_name].include?(rn) }
            next if fresh_rns.empty?

            seen_rn[table_name].merge(fresh_rns)
            would_by_table[table_name] += model.unscoped
              .where(RecordNumber: fresh_rns)
              .where("(#{table_name}.Confirmed & ?) = 0", bit)
              .count
          else
            model.unscoped
              .where(RecordNumber: record_numbers)
              .where("(#{table_name}.Confirmed & ?) = 0", bit)
              .update_all("Confirmed = Confirmed | #{bit.to_i}")
          end
        end
        update_slices += 1 unless dry
      end
      if (chunk_idx % 5).zero?
        msg = dry ? "chunks #{chunk_idx}, last PostemID #{last_id}" : "chunks #{chunk_idx}, ~#{update_slices} hash-slices"
        print "\r  #{msg}..."
        $stdout.flush
      end
    end
    puts "\r  postem stream done (#{chunk_idx} row-chunk(s))."
    would_by_table.each { |t, n| puts "         #{t}: #{n}" } if dry
    puts

    if dry
      puts "DRY RUN finished (no UPDATE executed)."
      next
    end

    puts "Finished (EntryPostem bit applied where rows matched and bit was unset)."
  end
end