desc "List VLD files with invalid civil parish"
require 'chapman_code'

task :list_vld_files_with_invalid_civil_parish, [:chapman, :limit] => :environment do |_t, args|

  args.with_defaults(:limit => 0) # ie no limit

  if args.chapman.nil?
    message = 'Chapman Code parameter must be supplied'
    exit
  end

  chapman_code = args.chapman.to_s
  file_for_warning_messages = "log/list_vld_files_with_invalid_civil_parish_#{chapman_code}.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  message_file = File.new(file_for_warning_messages, 'w')
  csv_output_file_name = "log/list_vld_files_with_invalid_civil_parish_#{chapman_code}.csv"
  FileUtils.mkdir_p(File.dirname(csv_output_file_name))
  csv_output_file = File.new(csv_output_file_name, 'w')
  csv_output_file.puts 'chapman_code,vld_file,enumeration_district,vld_civil_parish,fc2_piece_number,fc2_piece_civil_parishes(hamlets)'
  limit = args.limit.to_i
  file_count = 0
  counties = "#{ChapmanCode.name_from_code(chapman_code)}(#{chapman_code})"
  time_start = Time.now.utc
  limit_text = limit.positive? ? " with a limit of #{limit} VLD file(s)" : ''
  message = "#{time_start.strftime('%d/%m/%Y %H:%M:%S')} Starting list of VLD files with invalid civil parish for #{counties}#{limit_text}"
  output_to_log(message_file, message)

  files = Freecen1VldFile.where(dir_name: chapman_code).order_by(file_name: 1)

  civil_parishes = []
  message = "Total of #{files.length} files to process for #{counties}"
  output_to_log(message_file, message)

  files.each do |file|
    file_count += 1
    next if limit.positive? && file_count > limit

    entries = Freecen1VldEntry.where(freecen1_vld_file_id: file.id)

    message = "Processing #{file.file_name} with #{entries.length} entries"
    output_to_log(message_file, message)

    file_name = file.file_name
    fc2_piece = Freecen2Piece.find_by(_id: file.freecen2_piece_id)

    if fc2_piece.present?
      fc2_piece_number = fc2_piece.number
      fc2_piece_civil_parishes = fc2_piece.civil_parish_names
    else
      fc2_piece_number = '**MISSING**'
      fc2_piece_civil_parishes = '**MISSING**'
    end

    entries.each do |entry|
      unless civil_parish_valid(entry.civil_parish, fc2_piece_civil_parishes)
        compute_duplicate(chapman_code, civil_parishes, fc2_piece_civil_parishes, entry, file_name, fc2_piece_number)
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
    line << "#{problem_data[:fc2_piece_number]},"
    line << "\"#{problem_data[:fc2_piece_civil_parishes]}\""
    csv_output_file.puts line
  end
  message = "#{civil_parishes.length} issues with Civil Parish identified"
  output_to_log(message_file, message)
  time_end = Time.now.utc
  files_processed = limit.positive? ? limit : file_count
  run_time = time_end - time_start
  file_processing_average_time = run_time / files_processed
  message = "Average time to process a VLD file #{file_processing_average_time.round(2)} secs"
  output_to_log(message_file, message)
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
  just_civil_parish
end

def self.civil_parish_valid(civil_parish, fc2_piece_civil_parishes)
  return true if civil_parish == '-'

  return true if civil_parish == ''

  return true if civil_parish.blank?

  ignore_hamlets(fc2_piece_civil_parishes).include? civil_parish
end

def self.compute_duplicate(chapman_code, civil_parishes, fc2_piece_civil_parishes, entry, file_name, fc2_piece_number)
  duplicate = {}
  duplicate[:chapman_code] = chapman_code
  duplicate[:file_name] = file_name
  duplicate[:enumeration_district] = entry.enumeration_district
  duplicate[:civil_parish] = entry.civil_parish
  duplicate[:fc2_piece_number] = fc2_piece_number
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
