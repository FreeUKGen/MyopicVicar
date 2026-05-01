# frozen_string_literal: true

# Build LegacySearchRecordByEntry from existing LegacySearchRecordMapping (flat) documents.
#
#   rake legacy_search_record_by_entry:backfill_from_flat
#   rake legacy_search_record_by_entry:backfill_from_flat[dry_run]
#
namespace :legacy_search_record_by_entry do
  desc "Merge flat LegacySearchRecordMapping into LegacySearchRecordByEntry (inverted)."
  task :backfill_from_flat, [:dry_run] => :environment do |_t, args|
    dry_run = args[:dry_run].to_s.downcase == 'dry_run'
    puts "Mode: #{dry_run ? 'DRY RUN' : 'LIVE'}"

    resolvable = 0
    new_id_additions = 0
    skipped_no_entry = 0
    skipped_blank_old = 0
    errors = 0

    LegacySearchRecordMapping.all.no_timeout.each do |mapping|
      old_id = mapping.old_id.to_s.strip
      if old_id.blank?
        skipped_blank_old += 1
        next
      end

      entry_id = LegacySearchRecordByEntry.freereg_entry_id_from_flat_mapping(mapping)
      if entry_id.blank?
        skipped_no_entry += 1
        next
      end

      resolvable += 1
      if dry_run
        new_id_additions += 1
      else
        before = LegacySearchRecordByEntry.find_by(freereg1_csv_entry_id: entry_id)
        had = before&.legacy_search_record_ids&.map(&:to_s)&.include?(old_id)
        LegacySearchRecordByEntry.add_legacy_id!(
          freereg1_csv_entry_id: entry_id,
          legacy_search_record_id: old_id
        )
        new_id_additions += 1 unless had
      end
    rescue StandardError => e
      errors += 1
      puts "Error old_id=#{mapping.old_id}: #{e.message}"
    end

    puts "Flat rows with resolvable freereg1_csv_entry_id: #{resolvable}"
    puts(dry_run ? "Would add to inverted (dry run): #{new_id_additions}" : "New legacy ids added to inverted: #{new_id_additions}")
    puts "Skipped (blank old_id): #{skipped_blank_old}"
    puts "Skipped (could not resolve freereg1_csv_entry_id): #{skipped_no_entry}"
    puts "Errors: #{errors}"
    puts 'Done.' unless dry_run
  end
end
