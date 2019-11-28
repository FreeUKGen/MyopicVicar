class ReportOnFilesForEachRegisterChurchPlace
  require 'csv'
  class << self
    def process(chapmancode)
      file_for_output = Rails.root.join('log', "#{chapmancode}_county_content_report.csv")
      FileUtils.mkdir_p(File.dirname(file_for_output))
      output_file = File.new(file_for_output, 'w')
      output_file.puts 'County,Place,Church,Register,File,Userid,Records,Min year,Max year'
      code = chapmancode.blank? || chapmancode == 'All' ? 'All' : chapmancode
      records = []
      record = []
      if code == 'All'
        ChapmanCode.chapman_codes_for_reg_county.each do |chapman_code|
          results = lines_for_chapman_code(records, chapman_code)
          results.each do |result|
            record << result if result.present?
          end
        end
      else
        result = lines_for_chapman_code(records, code)
        record << result if result.present?
      end
      record.each do |result|
        result.each do |line|
          line = line.tr('^', ',')
          output_file.puts line
        end
      end
      output_file.close
      file_for_output
    end

    def lines_for_chapman_code(records, chapman_code)
      line = ''
      places = Place.chapman_code(chapman_code).not_disabled.all.order_by(place_name: 1)
      if places.blank?
        place_name = 'No place'
        line = chapman_code.to_s + '^' + place_name
        records << line
        line = ''
      else
        places.each do |place|
          place_name = place.place_name
          churches = place.churches.order_by(church_name: 1)
          if churches.blank?
            line = chapman_code.to_s + '^' + place_name.to_s + '^' + 'No church'
            records << line
            line = ''
          else
            churches.each do |church|
              church_name = church.church_name
              registers = church.registers.order_by(register_type: 1)
              if registers.blank?
                line = chapman_code.to_s + '^' + place_name.to_s + '^' + church_name.to_s + '^' + 'No register'
                records << line
                line = ''
              else
                registers.each do |register|
                  register_type = register.register_type
                  files = register.freereg1_csv_files.order_by(file_name: 1)
                  if files.blank?
                    line = chapman_code.to_s + '^' + place_name.to_s + '^' + church_name.to_s + '^' + register_type.to_s + '^' + 'No batch'
                    records << line
                    line = ''
                  else
                    files.each do |file|
                      line =  line = chapman_code.to_s + '^' + place_name.to_s + '^' + church_name.to_s + '^' + register_type.to_s + '^' + file.file_name.to_s
                      line =  line + '^' + file.userid.to_s
                      line =  line + '^' + file.records.to_s
                      line =  line + '^' + file.datemin.to_s
                      line =  line + '^' + file.datemax.to_s
                      records << line
                      line = ''
                    end
                  end
                end
              end
            end
          end
        end
      end
      records
    end
  end
end
