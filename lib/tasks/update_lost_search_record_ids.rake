# frozen_string_literal: true

# Loads old SearchRecord id -> new SearchRecord id mapping from a CSV and populates
# LegacySearchRecordMapping. Old citation/record URLs then redirect to the current record.
#
# CSV format: two columns — old/lost id and current id. Header row optional.
# Examples:
#   old_id,new_id
#   507f1f77bcf86cd799439011,507f191e810c19729de860ea
# or:
#   lost_id,current_id
#   507f1f77bcf86cd799439011,507f191e810c19729de860ea
#
# Usage:
#   RAILS_ENV=production bundle exec rake update_lost_search_record_ids[path/to/mapping.csv]
#   rake "update_lost_search_record_ids[dry_run]"  # with csv path for dry run
#
namespace :update_lost_search_record_ids do
  desc "Load CSV of old_id,new_id (or lost_id,current_id) and create LegacySearchRecordMapping records."
  task :from_csv, [:csv_path, :dry_run] => :environment do |_t, args|
    csv_path = args[:csv_path].to_s
    dry_run = args[:dry_run].to_s.downcase == 'dry_run'

    if csv_path.blank?
      puts "Usage: rake update_lost_search_record_ids:from_csv[path/to/mapping.csv]"
      puts "CSV must have two columns: old_id and new_id (or lost_id and current_id). Header row optional."
      next
    end

    path = Pathname.new(csv_path)
    path = Rails.root.join(csv_path) unless path.absolute?
    unless File.file?(path)
      puts "File not found: #{path}"
      next
    end

    puts "Mode: #{dry_run ? 'DRY RUN (no writes)' : 'LIVE'}"
    puts "CSV: #{path}"

    created = 0
    updated = 0
    skipped = 0
    errors = 0

    require 'csv'
    table = CSV.read(path.to_s, headers: true)
    headers = table.headers
    # Allow old_id/new_id or lost_id/current_id (case-insensitive, strip)
    norm = ->(h) { h.to_s.strip.downcase.gsub(/\s+/, '_') }
    old_col = headers.find { |h| norm[h] == 'old_id' } || headers.find { |h| norm[h] == 'lost_id' }
    new_col = headers.find { |h| norm[h] == 'new_id' } || headers.find { |h| norm[h] == 'current_id' }

    if old_col.nil? || new_col.nil?
      puts "CSV must have columns 'old_id' and 'new_id' (or 'lost_id' and 'current_id'). Headers: #{headers.inspect}"
      next
    end

    table.each do |row|
      old_id = row[old_col].to_s.strip
      new_id = row[new_col].to_s.strip
      if old_id.blank? || new_id.blank?
        skipped += 1
        next
      end
      next if old_id == new_id

      unless dry_run
        rec = LegacySearchRecordMapping.find_or_initialize_by(old_id: old_id)
        if rec.new_record?
          rec.new_id = new_id
          rec.save!
          created += 1
        else
          rec.update_attributes!(new_id: new_id)
          updated += 1
        end
      else
        created += 1
      end
    rescue StandardError => e
      errors += 1
      puts "Error row old_id=#{old_id} new_id=#{new_id}: #{e.message}"
    end

    puts "Created: #{created}, Updated: #{updated}, Skipped: #{skipped}, Errors: #{errors}"
    puts "Done." unless dry_run
  end

  desc "Build LegacySearchRecordMapping by scanning SearchQuery snapshots once (CSV of lost SearchRecord ids only)."
  task :from_search_queries, [:lost_ids_csv, :dry_run, :after_c_at, :before_c_at, :batch_size] => :environment do |_t, args|
    require 'set'
    require 'csv'

    csv_path = args[:lost_ids_csv].to_s
    dry_run = args[:dry_run].to_s.downcase == 'dry_run'
    after_c_at = args[:after_c_at].to_s
    before_c_at = args[:before_c_at].to_s
    batch_size = (args[:batch_size].presence || 500).to_i

    if csv_path.blank?
      puts "Usage: rake update_lost_search_record_ids:from_search_queries[lost_ids.csv, dry_run|, after_c_at, before_c_at, batch_size]"
      puts "CSV should be one column of old/lost SearchRecord ids (header optional)."
      abort
    end

    path = Pathname.new(csv_path)
    path = Rails.root.join(csv_path) unless path.absolute?
    unless File.file?(path)
      puts "File not found: #{path}"
      abort
    end

    # Load ids from CSV (header optional). Also tolerates comma-separated lines; first token wins.
    lost_ids = Set.new
    File.readlines(path.to_s).each do |line|
      line = line.strip
      next if line.blank?
      next if line =~ /\A(old_id|lost_id|search_record_id)\b/i
      first = line.split(',').first.to_s.strip
      next unless first =~ /\A[0-9a-fA-F]{24}\z/
      lost_ids.add(first.downcase)
    end

    puts "Loaded lost ids: #{lost_ids.size}"
    if lost_ids.empty?
      abort
    end

    # Optional rebuild-window filtering
    query = {}
    if after_c_at.present? || before_c_at.present?
      after_time = after_c_at.present? ? (Time.parse(after_c_at) rescue nil) : nil
      before_time = before_c_at.present? ? (Time.parse(before_c_at) rescue nil) : nil
      if after_time && before_time
        query[:c_at] = after_time..before_time
      elsif after_time
        query[:c_at] = { '$gte' => after_time }
      elsif before_time
        query[:c_at] = { '$lte' => before_time }
      end
    end

    # Scan SearchQuery snapshots once and extract freereg1_csv_entry_id from embedded record hashes
    projection = { 'search_result.records' => 1, '_id' => 1 }

    mapping_old_to_entry_oid = {} # old_id(string) => entry_oid (BSON::ObjectId or string)
    scanned = 0
    matched = 0
    missing_entry_id = 0

    puts "Scanning SearchQuery snapshots (batch_size=#{batch_size})..."
    cursor = SearchQuery.collection.find(query, projection).batch_size(batch_size)
    cursor.each do |doc|
      scanned += 1
      records_hash = doc['search_result'] && doc['search_result']['records']
      next unless records_hash.is_a?(Hash)

      records_hash.each do |old_id_key, rec_hash|
        old_id = old_id_key.to_s.downcase
        next unless lost_ids.include?(old_id)
        next if mapping_old_to_entry_oid.key?(old_id)
        next unless rec_hash.is_a?(Hash)

        entry_id = rec_hash['freereg1_csv_entry_id'] || rec_hash[:freereg1_csv_entry_id]
        if entry_id.present?
          mapping_old_to_entry_oid[old_id] = entry_id
          matched += 1
        else
          missing_entry_id += 1
        end
      end

      if (scanned % (batch_size * 10)).zero?
        puts "Scanned=#{scanned}, mapped=#{mapping_old_to_entry_oid.size}, matched_old_ids=#{matched}, missing_entry_id=#{missing_entry_id}"
      end
    end

    puts "Scan complete. scanned=#{scanned}, mapped_old_to_entry=#{mapping_old_to_entry_oid.size}, missing_entry_id=#{missing_entry_id}"

    entry_ids = mapping_old_to_entry_oid.values.compact.uniq
    if entry_ids.empty?
      abort
    end

    entry_oids = entry_ids.map do |v|
      if v.is_a?(BSON::ObjectId)
        v
      else
        BSON::ObjectId.from_string(v.to_s) rescue nil
      end
    end.compact.uniq

    if entry_oids.empty?
      abort
    end

    # Map entry_oid => new SearchRecord id
    entry_oid_to_new_id = {}
    SearchRecord.collection.find(
      { freereg1_csv_entry_id: { '$in' => entry_oids } },
      { '_id' => 1, 'freereg1_csv_entry_id' => 1 }
    ).each do |sr|
      entry_oid_to_new_id[sr['freereg1_csv_entry_id'].to_s] = sr['_id'].to_s
    end

    puts "Found current SearchRecords for entry_ids: #{entry_oid_to_new_id.size}"

    created = 0
    updated = 0
    skipped = 0
    failed = 0

    mapping_old_to_entry_oid.each do |old_id, entry_id|
      entry_oid = entry_id.is_a?(BSON::ObjectId) ? entry_id.to_s : (BSON::ObjectId.from_string(entry_id.to_s).to_s rescue nil)
      new_id = entry_oid ? entry_oid_to_new_id[entry_oid] : nil
      if new_id.blank?
        failed += 1
        next
      end

      existing = LegacySearchRecordMapping.find_by(old_id: old_id)
      if existing.present?
        if existing.new_id.to_s != new_id
          unless dry_run
            existing.update_attributes!(new_id: new_id)
          end
          updated += 1
        else
          skipped += 1
        end
      else
        unless dry_run
          LegacySearchRecordMapping.create!(old_id: old_id, new_id: new_id)
        end
        created += 1
      end
    end

    puts "Mapping results: created=#{created}, updated=#{updated}, skipped=#{skipped}, failed=#{failed}"
    puts "Done." unless dry_run
  end
end

# Default: run from CSV (pass path as first arg)
task :update_lost_search_record_ids, [:csv_path] => :environment do |_t, args|
  path = args[:csv_path].to_s
  if path.present?
    Rake::Task['update_lost_search_record_ids:from_csv'].invoke(path)
  else
    puts "Usage: rake update_lost_search_record_ids[path/to/mapping.csv]"
    puts "CSV format: old_id,new_id (or lost_id,current_id). One row per mapping."
  end
end
