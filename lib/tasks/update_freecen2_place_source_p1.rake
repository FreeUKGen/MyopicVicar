desc 'Update Freecen2 Place Source Pass 1 from CSV file supplied by GJ'
task Update_Freecen2_Place_Source_P1:  :environment do
  require 'csv'

  file_for_warning_messages = "#{Rails.root}/log/Update_Freecen2_Place_Source_P1.txt"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  output_file = File.new(file_for_warning_messages, 'a')
  input_file = "#{Rails.root}/tmp/freecen2_place_sources_p1_updates.csv"

  output_file.puts "Started update of Freecen2_place sources Pass 1 at #{Time.now}"

  p '*** Started update of Freecen2_place sources Pass 1'

  if File.exist?(input_file)

    row_cnt = 0
    total_rows = 0
    upd_cnt = 0

    CSV.foreach(input_file, quote_char: '"', col_sep: ',', headers: true, header_converters: :symbol) do |row|
      total_rows += 1
      if row[:new_source].present? && row[:chapman_code].present? && row[:place_name].present?
        if Freecen2PlaceSource.find_by(source: row[:new_source]).present?
          row_cnt += 1
          if Freecen2Place.find_by(chapman_code: row[:chapman_code], place_name: row[:place_name], source: row[:existing_source]).present? && row[:existing_source] != '(source missing)'
            upd_cnt += 1
            place = Freecen2Place.find_by(chapman_code: row[:chapman_code], place_name: row[:place_name], source: row[:existing_source])
            place.set(source: row[:new_source])
            output_file.puts row
            output_file.puts '***** Record updated'
          elsif
            Freecen2Place.find_by(chapman_code: row[:chapman_code], place_name: row[:place_name], source: nil).present? && row[:existing_source] == '(source missing)'
            upd_cnt += 1
            place = Freecen2Place.find_by(chapman_code: row[:chapman_code], place_name: row[:place_name], source: nil)
            place.set(source: row[:new_source])
            output_file.puts row
            output_file.puts '***** Record updated'
          else
            output_file.puts row
            output_file.puts "Freecen2Place record not found for row #{row_cnt}"
            p "Freecen2Place record not found for row #{row_cnt}"
          end
        else
          output_file.puts "New Source is not a valid freecen2_place_source #{row[:new_source]} - row number #{total_rows + 1} in CSV input file"
        end
      end
    end
  else
    output_file.puts "CSV input file not found - #{input_file}"
    puts "CSV input file not found - #{input_file}"
  end

  output_file.puts "Finished update of Freecen2_place sources Pass 1 at #{Time.now}"

  output_file.close

  p "Total records in CSV file = #{total_rows}"

  p "CSV file records with New_source specified = #{row_cnt}"

  p "Freecen2 Place records updated = #{upd_cnt}"

  p '*** Finished update of Freecen2_place sources Pass 1'
end
