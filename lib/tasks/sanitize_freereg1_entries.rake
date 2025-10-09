namespace :freereg do
  desc "Trim and normalize whitespace in all string fields of Freereg1CsvEntry records"
  task sanitize_existing_entries: :environment do
    puts "Starting sanitization of Freereg1CsvEntry records..."
    updated_count = 0
    skipped_count = 0
    error_count = 0

    Freereg1CsvEntry.find_each(batch_size: 1000) do |entry|
      begin
        modified = false
        entry.attributes.each do |attr, value|
          next unless value.is_a?(String)

          sanitized = value.strip.gsub(/\s+/, ' ')
          if sanitized != value
            entry[attr] = sanitized
            modified = true
          end
        end

        if modified
          entry.save!(validate: false)
          updated_count += 1
        else
          skipped_count += 1
        end
      rescue => e
        puts "Error updating entry ID #{entry.id}: #{e.message}"
        error_count += 1
      end
    end

    puts "Sanitization complete."
    puts "Updated records: #{updated_count}"
    puts "Unchanged records: #{skipped_count}"
    puts "Errors: #{error_count}"
  end
end