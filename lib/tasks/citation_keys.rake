# frozen_string_literal: true

namespace :citation_keys do
  desc 'Assign citation_key to FreeREG Freereg1CsvEntry rows and their SearchRecords (missing keys only)'
  task backfill: :environment do
    puts 'Backfilling Freereg1CsvEntry...'
    total = 0
    Freereg1CsvEntry.where(citation_key: nil).no_timeout.each do |doc|
      doc.ensure_citation_key!
      doc.save(validate: false)
      total += 1
      puts "  #{total} Freereg1CsvEntry records..." if (total % 10_000).zero?
    end
    puts "  Freereg1CsvEntry: #{total} updated."

    puts 'Backfilling SearchRecord (FreeREG only: freereg1_csv_entry present)...'
    sr_total = 0
    SearchRecord.where(citation_key: nil).no_timeout.each do |sr|
      key = sr.freereg1_csv_entry&.citation_key
      if key.present?
        sr.citation_key = key
        sr.save(validate: false)
      else
        sr.ensure_citation_key!
        sr.save(validate: false)
      end
      sr_total += 1
      puts "  #{sr_total} SearchRecord records..." if (sr_total % 10_000).zero?
    end
    puts "  SearchRecord: #{sr_total} updated."
    puts 'Done.'
  end
end
