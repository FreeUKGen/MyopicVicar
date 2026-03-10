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

  desc "Insert Postems from CSV that don't already exist (by Hash + Information). FILE=path required. Streams file and batch-inserts."
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
          'Information' => row['Information'].to_s[0, Postem::MAX_INFORMATION_LENGTH],
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
end
