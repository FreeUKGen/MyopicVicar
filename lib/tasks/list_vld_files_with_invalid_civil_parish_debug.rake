desc "List VLD files with invalid civil parish"
require 'chapman_code'

task :list_vld_files_with_invalid_civil_parish, [:start_chapman, :limit, :userid] => :environment do |_t, args|

  args.with_defaults(:limit => 500)

  if args.start_chapman.nil?
    message = 'Starting Chapman Code parameter must be supplied'
    exit
  end

  start_chapman_code = args.start_chapman.to_s
  output_file_name = "log/list_vld_files_with_invalid_civil_parish_#{start_chapman_code}"
  file_for_warning_messages = "#{output_file_name}.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  message_file = File.new(file_for_warning_messages, 'w')
  csv_output_file_name = "#{output_file_name}.csv"
  FileUtils.mkdir_p(File.dirname(csv_output_file_name))
  csv_output_file = File.new(csv_output_file_name, 'w')
  csv_header = 'chapman_code,vld_file,enumeration_district,vld_civil_parish,fc2_piece_number,fc2_piece_civil_parishes(hamlets)'
  csv_output_file.puts csv_header
  limit = args.limit.to_i
  userid = args.userid.present? ? args.userid.to_s : 'n/a'
  file_count = 0
  counties_text = "#{ChapmanCode.name_from_code(start_chapman_code)}(#{start_chapman_code})"
  time_start = Time.now.utc
  limit_text = limit.positive? && userid != 'n/a' ? " and a limit of #{limit} VLD file(s)" : ''
  message = "#{time_start.strftime('%d/%m/%Y %H:%M:%S')} Starting list of VLD files with invalid civil parish starting with #{counties_text}#{limit_text}"
  output_to_log(message_file, message)

  unless userid == 'n/a'
    vld_counties = []
    vld_counties << start_chapman_code
    report_csv = ''
  else
    vld_counties = Freecen1VldFile.distinct('dir_name')
    vld_counties.sort!
  end

  message = "VLD file chapman count = #{vld_counties.length} : #{vld_counties}"
  output_to_log(message_file, message)

  process_county = false
  vld_counties.each do |county|

    process_county = true if county == start_chapman_code

    process_county = false if file_count >= limit

    if process_county

      chapman_code = county

      files = Freecen1VldFile.where(dir_name: chapman_code).order_by(file_name: 1)

      civil_parishes = []
      counties_text = "#{ChapmanCode.name_from_code(chapman_code)}(#{chapman_code})"
      message = "Total of #{files.length} files to process for #{counties_text}"
      output_to_log(message_file, message)

      files.each do |file|
        file_count += 1

        entries = Freecen1VldEntry.where(freecen1_vld_file_id: file.id).order_by(enumeration_district: 1, civil_parish: 1)

        message = "Processing #{file.file_name} with #{entries.length} entries"
        output_to_log(message_file, message)

        file_name = file.file_name
        fc2_piece_main = Freecen2Piece.find_by(_id: file.freecen2_piece_id)

        fc2_piece_numbers = ''
        fc2_piece_civil_parishes = ''

        if fc2_piece_main.present?

          fc2_piece_numbers += "#{fc2_piece_main.number}, "
          fc2_piece_civil_parishes = get_civil_parishes(fc2_piece_main, fc2_piece_civil_parishes)

          message = "Processing main piece: #{fc2_piece_numbers}"
          output_to_log(message_file, message)

          message = "Processing main civil parishes: #{fc2_piece_civil_parishes}"
          output_to_log(message_file, message)

          # Is the last charcaacter an alphabetic, if so remove before looking for 'parts'
          fc2_piece_base = fc2_piece_main.number[-1..-1].match?(/[A-Za-z]/) ? fc2_piece_main.number.chop : fc2_piece_main.number

          regexp = BSON::Regexp::Raw.new('^' + fc2_piece_base + '\D')
          parts = Freecen2Piece.where(number: regexp).order_by(number: 1)
          message = "Parts #{parts.count}"
          output_to_log(message_file, message)

          if parts.count.positive?
            parts.each do |part|
              if part.number != fc2_piece_main.number
                fc2_piece_numbers += "#{part.number}, "
                fc2_piece_civil_parishes = get_civil_parishes(part, fc2_piece_civil_parishes)
              end
            end

          end

        else
          fc2_piece_numbers += '**MISSING**, '
          fc2_piece_civil_parishes += '**MISSING**, '
        end

        message = "All Piece numbers: #{fc2_piece_numbers}"
        output_to_log(message_file, message)

        message = "All Civil_Parishes: #{fc2_piece_civil_parishes}"
        output_to_log(message_file, message)

        fc2_piece_numbers = fc2_piece_numbers[0...-2]
        fc2_piece_civil_parishes = fc2_piece_civil_parishes[0...-2]

        entries.each do |entry|
          unless civil_parish_valid(entry.civil_parish, fc2_piece_civil_parishes)
            compute_duplicate(chapman_code, civil_parishes, fc2_piece_civil_parishes, entry, file_name, fc2_piece_numbers)
          end

          #   end entry
        end

        # end file
      end

      civil_parishes.each do |problem_data|
        line = ''
        line << "#{problem_data[:chapman_code]},"
        line << "#{problem_data[:file_name]},"
        line << "#{problem_data[:enumeration_district]},"
        line << "\"#{problem_data[:civil_parish]}\","
        line << "\"#{problem_data[:fc2_piece_numbers]}\","
        line << "\"#{problem_data[:fc2_piece_civil_parishes]}\""
        csv_output_file.puts line

        unless userid == 'n/a'
          report_csv = csv_header  if report_csv.length == 0
          report_csv += "\n"
          report_csv += line
        end
      end
      message = "#{civil_parishes.length} issues with Civil Parish identified for #{chapman_code}"
      output_to_log(message_file, message)
      time_end = Time.now.utc
      files_processed = limit.positive? ? limit : file_count
      run_time = time_end - time_start
      file_processing_average_time = run_time / files_processed
      message = "Average time to process a VLD file #{file_processing_average_time.round(2)} secs"
      output_to_log(message_file, message)
      @last_chapman_code = chapman_code

    end

    # end vld_counties loop
  end

  message = "**** FINAL COUNTY Processed : #{@last_chapman_code} ****"
  output_to_log(message_file, message)

  # Rename the output files

  new_csv_output_file_name = "#{output_file_name}_#{@last_chapman_code}.csv"
  new_file_for_warning_messages = "#{output_file_name}_#{@last_chapman_code}.log"

  FileUtils.mv csv_output_file_name, new_csv_output_file_name
  FileUtils.mv file_for_warning_messages, new_file_for_warning_messages

  message = "See #{new_file_for_warning_messages} and #{new_csv_output_file_name} for output"
  output_to_log(message_file, message)

  unless userid == 'n/a'
    require 'user_mailer'
    user_rec = UseridDetail.userid(userid).first

    email_subject = "FreeCEN: VLD files with invalid Civil Parishes in #{start_chapman_code}"
    email_body = report_csv == '' ? 'No invalid Civil Parishes found.' : 'See attached CSV file.'
    report_name = "FreeCEN_VLD_invalid_civil_parishes_#{start_chapman_code}.csv"
    email_to = user_rec.email_address

    p "sending email to #{userid} - list of VLD files with invalid parishes attached"

    UserMailer.freecen_vld_invalid_civil_parish_report(email_subject, email_body, report_csv, report_name, email_to).deliver_now
  end

  time_end = Time.now.utc
  message = "#{time_end.strftime('%d/%m/%Y %H:%M:%S')} Finished"
  output_to_log(message_file, message)

  # end task
end

def self.output_to_log(message_file, message)
  message_file.puts message.to_s
  p message.to_s
end

def self.ignore_hamlets(civil_parish_names)
  just_civil_parish = ''
  ignore = false
  civil_parish_names.split('').each do |char|
    if char == '('
      ignore = true
      next
    end
    if ignore == true && char == ')'
      ignore = false
      next
    end
    just_civil_parish += char if ignore == false
  end
  just_civil_parish.downcase
end

def self.ignore_hyphens(civil_parish_names)
  cps_no_hyphens = civil_parish_names.gsub('-', ' ')
end

def self.get_civil_parishes(piece, civil_parishes)
  cp_names = ''
  if piece.civil_parish_names.present?
    cp_names = piece.civil_parish_names
  elsif civil_parishes == ''
    cp_names = '**MISSING**'
  end
  civil_parishes += "#{cp_names}, " if cp_names != ''
end

def self.civil_parish_valid(civil_parish, fc2_piece_civil_parishes)
  return true if civil_parish == '-'

  return true if civil_parish == ''

  return true if civil_parish.blank?

  cps_to_match = ignore_hamlets(fc2_piece_civil_parishes)
  ignore_hyphens(cps_to_match).include? civil_parish.downcase
end

def self.compute_duplicate(chapman_code, civil_parishes, fc2_piece_civil_parishes, entry, file_name, fc2_piece_numbers)
  duplicate = {}
  duplicate[:chapman_code] = chapman_code
  duplicate[:file_name] = file_name
  duplicate[:enumeration_district] = entry.enumeration_district
  duplicate[:civil_parish] = entry.civil_parish
  duplicate[:fc2_piece_numbers] = fc2_piece_numbers
  duplicate[:fc2_piece_civil_parishes] = fc2_piece_civil_parishes
  civil_parishes << duplicate if add_to_collection(civil_parishes, duplicate)
end

def self.add_to_collection(civil_parishes, civil_parish)
  result = true
  civil_parishes.each do |parish|
    if parish[:file_name] == civil_parish[:file_name] && parish[:enumeration_district] == civil_parish[:enumeration_district] &&
        parish[:civil_parish] == civil_parish[:civil_parish]
      result = false
      break
    end
  end
  result
end
