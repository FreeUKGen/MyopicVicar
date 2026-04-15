# frozen_string_literal: true

namespace :citation_keys do
  desc 'Assign citation_key to source rows and search records that are missing one (batched)'
  task backfill: :environment do
    [Freereg1CsvEntry, FreecenCsvEntry, FreecenIndividual].each do |model|
      name = model.name
      puts "Backfilling #{name}..."
      total = 0
      model.where(citation_key: nil).no_timeout.each do |doc|
        doc.ensure_citation_key!
        doc.save(validate: false)
        total += 1
        puts "  #{total} #{name} records..." if (total % 10_000).zero?
      end
      puts "  #{name}: #{total} updated."
    end

    puts 'Backfilling SearchRecord from linked entries where possible...'
    sr_total = 0
    SearchRecord.where(citation_key: nil).no_timeout.each do |sr|
      key = sr.freereg1_csv_entry&.citation_key
      key ||= sr.freecen_csv_entry&.citation_key
      key ||= sr.freecen_individual&.citation_key
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
