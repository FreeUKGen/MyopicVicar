desc "Fill_csv_file_lower_case: Populate Freecen_csv_files file_name_lower_case."

task Fill_csv_file_lower_case: :environment do

  file_for_warning_messages = "#{Rails.root}/log/Fill_csv_file_lower_case.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  output_file = File.new(file_for_warning_messages, 'w')

  puts 'Fill_csv_file_lower_case: Started.'

  output_file.puts 'Fill_csv_file_lower_case: Started.'

  start_time = Time.current
  csv_file_records = 0
  csv_file_successful_records = 0

  FreecenCsvFile.no_timeout.each do |rec|

    csv_file_records += 1

    if rec.update_attributes(file_name_lower_case: rec.file_name.downcase)
      csv_file_successful_records += 1
    end

    output_file.puts "Fill_csv_file_lower_case: #{csv_file_records} records processed so far." if (csv_file_records % 1000).zero?

  end

  output_file.puts "Fill_csv_file_lower_case: Out of #{csv_file_records} total freecen_csv_file records, #{csv_file_successful_records} records updated successfully"
  output_file.puts "Fill_csv_file_lower_case: Completed in #{Time.current - start_time} seconds."

  puts "Fill_csv_file_lower_case: Completed in #{Time.current - start_time} seconds."
end
