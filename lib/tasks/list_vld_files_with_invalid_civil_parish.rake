desc "List VLD files with invalid civil parish"
require 'chapman_code'

task :list_vld_files_with_invalid_civil_parish, [:chapman, :limit] => :environment do |_t, args|

  args.with_defaults(:chapman => 'ALL', :limit => 0) # ie no limit

  file_for_warning_messages = 'log/list_vld_files_with_invalid_civil_parish.csv'
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  message_file = File.new(file_for_warning_messages, 'w')
  message_file.puts 'chapman_code,vld_file,enumeration_district,vld_civil_parish,fc2_piece_number,fc2_piece_civil_parishes(hamlets)'
  chapman_code = args.chapman.to_s
  limit = args.limit.to_i
  file_count = 0
  this_chapman_code = nil
  counties = chapman_code == 'ALL' ? 'All Counties' : "#{ChapmanCode.name_from_code(chapman_code)}(#{chapman_code})"
  limit_text = limit.positive? ? " with a limit of #{limit} VLD file(s)" : ''
  p "Starting list of VLD files with invalid civil parish for #{counties}#{limit_text}"
  if chapman_code == 'ALL'
    files = Freecen1VldFile.order_by(dir_name: 1, file_name: 1)
  else
    files = Freecen1VldFile.where(dir_name: chapman_code).order_by(file_name: 1)
  end

  civil_parishes = []
  p "Total of #{files.length} files to process for #{counties}"

  files.each do |file|
    file_count += 1
    next if limit.positive? && file_count > limit

    if this_chapman_code.blank? || this_chapman_code != file.dir_name
      p "Working on #{file.dir_name}"
      this_chapman_code = file.dir_name
    end

    entries = Freecen1VldEntry.where(freecen1_vld_file_id: file.id)

    p "Processing #{file.file_name} with #{entries.length} entries"

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
        compute_duplicate(this_chapman_code, civil_parishes, fc2_piece_civil_parishes, entry, file_name, fc2_piece_number)
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
    message_file.puts line
  end
  p "#{civil_parishes.length} issues with Civil Parish identified"
  p 'Finished'

  # end task
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
