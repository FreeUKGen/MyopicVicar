task :clean_vld_civil_parish_names, [:chapman_code, :file_limit, :fix] => [:environment] do |t, args|
  p "Started clean_vld_civil_parish_names #{args.chapman_code}  #{args.file_limit} #{args.fix}"
  clean_name(args.chapman_code, args.file_limit, args.fix)
  p 'Finished'
end

def clean_name(chapman_code, file_limit, fix)
  time_start = Time.now.utc
  num_files = 0
  @num_fixed = 0
  @num_to_fix = 0
  @needs_fix = false
  county = chapman_code.to_s.downcase == 'all' ? 'all' : chapman_code.to_s
  lim = file_limit.to_i
  fixit = fix.to_s.downcase == 'y' ? true : false
  p "#{time_start.strftime('%d/%m/%Y %H:%M:%S')} County=#{county} file_limit=#{lim} fixit=#{fixit}"

  file_for_warning_messages = "log/clean_vld_civil_parish_names_#{county}_#{time_start.strftime("%Y%m%d%H%M%S")}.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  @message_file = File.new(file_for_warning_messages, 'w')

  vld_file_count = county == 'all' ? Freecen1VldFile.count : Freecen1VldFile.where(dir_name: county).count
  scope = county == 'all' ? 'All counties have' : "#{county} has"
  p "#{scope} #{vld_file_count} files"

  vld_files = county == 'all' ? Freecen1VldFile.order_by(dir_name: 1, file_name: 1).pluck(:id, :dir_name, :file_name, :num_entries) : Freecen1VldFile.where(dir_name: county).order_by(file_name: 1).pluck(:id, :dir_name, :file_name, :num_entries)

  vld_files.each do |vld_file|

    num_files += 1
    break if num_files > lim

    @vld_file_id = vld_file[0]
    @vld_chapman_code = vld_file[1]
    @vld_file_name = vld_file[2]
    @vld_num_entries = vld_file[3]

    @message_text = "Working on VLD File  #{@vld_chapman_code} #{@vld_file_name } with #{@vld_num_entries} records"
    p @message_text
    @message_file.puts "#{@message_text}"

    @this_enum = ''
    @this_civil_parish = ''

    vld_entries = Freecen1VldEntry.where(freecen1_vld_file_id: @vld_file_id).order_by(enumeration_district: 1, civil_parish: 1).pluck(:id, :enumeration_district, :civil_parish)

    vld_entries.each do |vld_entry|

      the_enum = vld_entry[1]
      the_civil_parish = vld_entry[2]

      new_enum_civil_parish = @this_enum == '' || @this_civil_parish == '' || @this_enum != the_enum || @this_civil_parish != the_civil_parish ? true : false

      next unless new_enum_civil_parish

      @num_fixed = update_vld_records(@vld_chapman_code, @vld_file_id, @vld_file_name, @this_enum, @this_civil_parish, @new_vld_civil_parish, @num_fixed) if fixit && @needs_fix
      @this_enum = the_enum
      @this_civil_parish = the_civil_parish
      @vld_entry_id = vld_entry[0]
      @vld_enum = vld_entry[1]
      @vld_civil_parish = vld_entry[2]

      @needs_fix = false

      unless @vld_civil_parish.blank?

        # 1. look for all occurances of &

        @needs_fix, @fixed1 = look_for_ampersands(@vld_civil_parish)

        # 2. look for all occurances of ,

        @needs_fix, @fixed2 = look_for_commas(@fixed1, @needs_fix)

        # 3. then look for all occurances of 2 spaces

        @needs_fix, @new_vld_civil_parish = look_for_extra_spaces(@fixed2, @needs_fix)

        @num_to_fix += 1 if @needs_fix == true

      end
    end
    # Fix last enumeration district?
    @num_fixed = update_vld_records(@vld_chapman_code, @vld_file_id, @vld_file_name, @this_enum, @this_civil_parish, @new_vld_civil_parish, @num_fixed) if fixit && @needs_fix
  end
  files_processed = lim < vld_file_count ? lim : vld_file_count
  time_end = Time.now.utc
  run_time = time_end - time_start
  file_processing_average_time = run_time / files_processed
  p "Processed #{files_processed} vld files"
  p "Needing fix #{@num_to_fix} issues"
  p "Fixed #{@num_fixed} issues"
  p "Average time to process a file #{file_processing_average_time.round(2)} secs"
  p "Run time = #{run_time.round(2)} secs"
  p "#{time_end.strftime('%d/%m/%Y %H:%M:%S')} Finished"
end

def look_for_ampersands(civil_parish)
  to_fix = false
  find1 = (0...civil_parish.length).find_all { |i| civil_parish[i, 1] == '&' }
  if find1.length.positive?
    to_fix = true
    fixed1 = civil_parish.gsub('&', ' and ')
    @message_text = "#{civil_parish} : found #{find1.length} ampersand(s)"
    @message_file.puts "#{@message_text}"
  else
    fixed1 = civil_parish
  end
  [to_fix, fixed1]
end

def look_for_commas(civil_parish, needs_fix)
  find2 = (0...civil_parish.length).find_all { |i| civil_parish[i, 1] == ',' }
  if find2.length.positive?
    needs_fix = true
    fixed2 = civil_parish.gsub(',', ' ')
    @message_text = "#{civil_parish}: found #{find2.length} comma(s)"
    @message_file.puts "#{@message_text}"
  else
    fixed2 = civil_parish
  end
  [needs_fix, fixed2]
end

def look_for_extra_spaces(civil_parish, needs_fix)
  fixed3 = civil_parish.strip.squeeze(' ')
  unless fixed3 == civil_parish
    needs_fix = true
    @message_text = "#{civil_parish}: found multiple spaces"
    @message_file.puts "#{@message_text}"
  end
  [needs_fix, fixed3]
end

def update_vld_records(chapman_code, file_id, file_name, enum, civil_parish, new_civil_parish, num_fixed)
  @message_text = "#{chapman_code} #{file_name} #{enum} #{civil_parish}: fixed_name: #{new_civil_parish}"
  @message_file.puts "#{@message_text}"

  num_records_to_update = Freecen1VldEntry.where(freecen1_vld_file_id: file_id, enumeration_district: enum, civil_parish: civil_parish).count

  @message_text = "#{num_records_to_update} vld records to update"

  #AEV01 record_to_update.update(civil_parish: new_vld_civil_parish)

  num_fixed += 1
end
