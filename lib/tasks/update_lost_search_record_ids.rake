# frozen_string_literal: true

# Loads legacy SearchRecord id -> current target mapping into LegacySearchRecordMapping (flat)
# and LegacySearchRecordByEntry (inverted: legacy ids per freereg1_csv_entry_id).
# Old citation/record URLs then redirect to the current record.
#
# CSV: header row optional. Required: old_id (or lost_id) plus at least one of:
#   new_id / current_id (SearchRecord id or freereg1_csv_entry_id), and/or
#   freereg1_csv_entry_id (preferred redirect target for FreeREG).
#
# Examples:
#   old_id,new_id
#   507f1f77bcf86cd799439011,507f191e810c19729de860ea
#   old_id,freereg1_csv_entry_id
#   507f1f77bcf86cd799439011,507f191e810c19729de860ea
#   old_id,new_id,freereg1_csv_entry_id
#   507f...,507f...,507f...
#
# Usage:
#   RAILS_ENV=production bundle exec rake update_lost_search_record_ids[path/to/mapping.csv]
#   rake "update_lost_search_record_ids[dry_run]"  # with csv path for dry run
#
namespace :update_lost_search_record_ids do
  desc "Load CSV into LegacySearchRecordMapping (old_id + new_id and/or freereg1_csv_entry_id)."
  task :from_csv, [:csv_path, :dry_run] => :environment do |_t, args|
    csv_path = args[:csv_path].to_s
    dry_run = args[:dry_run].to_s.downcase == 'dry_run'

    if csv_path.blank?
      puts "Usage: rake update_lost_search_record_ids:from_csv[path/to/mapping.csv]"
      puts "CSV: old_id (or lost_id) plus new_id/current_id and/or freereg1_csv_entry_id. Header row optional."
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
    entry_col = headers.find { |h| norm[h] == 'freereg1_csv_entry_id' } ||
                headers.find { |h| norm[h] == 'csv_entry_id' } ||
                headers.find { |h| norm[h] == 'entry_id' }

    if old_col.nil? || (new_col.nil? && entry_col.nil?)
      puts "CSV must have 'old_id' (or 'lost_id') and at least one of 'new_id'/'current_id' or 'freereg1_csv_entry_id'. Headers: #{headers.inspect}"
      next
    end

    table.each do |row|
      old_id = row[old_col].to_s.strip
      new_id = new_col ? row[new_col].to_s.strip : ''
      entry_id = entry_col ? row[entry_col].to_s.strip : ''
      if old_id.blank? || (new_id.blank? && entry_id.blank?)
        skipped += 1
        next
      end
      next if old_id == new_id && entry_id.blank?
      next if old_id == entry_id && new_id.blank?

      unless dry_run
        rec = LegacySearchRecordMapping.find_or_initialize_by(old_id: old_id)
        attrs = {}
        attrs[:new_id] = new_id if new_id.present?
        attrs[:freereg1_csv_entry_id] = entry_id if entry_id.present?
        if rec.new_record?
          rec.assign_attributes(attrs)
          rec.save!
          created += 1
        else
          rec.update_attributes!(attrs)
          updated += 1
        end
        rec.reload
        entry_for_inverted = LegacySearchRecordByEntry.freereg_entry_id_from_flat_mapping(rec)
        LegacySearchRecordByEntry.add_legacy_id!(
          freereg1_csv_entry_id: entry_for_inverted,
          legacy_search_record_id: old_id
        ) if entry_for_inverted.present?
      else
        created += 1
      end
    rescue StandardError => e
      errors += 1
      puts "Error row old_id=#{old_id} new_id=#{new_id} freereg1_csv_entry_id=#{entry_id}: #{e.message}"
    end

    puts "Created: #{created}, Updated: #{updated}, Skipped: #{skipped}, Errors: #{errors}"
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
    puts "CSV: old_id + new_id/current_id and/or freereg1_csv_entry_id. One row per mapping."
  end
end
