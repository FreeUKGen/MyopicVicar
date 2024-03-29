desc 'Clean up civil Parish names in vld file entries and related dwelling records'
task :clean_vld_civil_parish_names, [:chapman_code, :file_limit, :fix] => [:environment] do |t, args|
  p "Started clean_vld_civil_parish_names #{args.chapman_code} #{args.file_limit} #{args.fix}"
  clean_name(args.chapman_code, args.file_limit, args.fix)
  p 'Finished'
end

def clean_name(chapman_code, file_limit, fix)
  time_start = Time.now.utc
  num_files = 0
  @num_fixed = 0
  @num_to_fix = 0
  county = chapman_code.to_s.downcase == 'all' ? 'all' : chapman_code.to_s
  lim = file_limit.to_i
  fixit = fix.to_s.downcase == 'y'

  file_for_warning_messages = "log/clean_vld_civil_parish_names_#{county}_#{time_start.strftime('%Y%m%d%H%M%S')}.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  @message_file = File.new(file_for_warning_messages, 'w')

  @message_text = "#{time_start.strftime('%d/%m/%Y %H:%M:%S')} County=#{county} file_limit=#{lim} fixit=#{fixit}"
  output_message(true, true)

  vld_file_count = county == 'all' ? Freecen1VldFile.count : Freecen1VldFile.where(dir_name: county).count
  scope = county == 'all' ? 'All counties have' : "#{county} has"
  mode = fixit ? 'This run will fix issues' : 'This run will just list issues'
  @message_text = "#{scope} #{vld_file_count} vld files - #{mode}"
  output_message(true, true)

  vld_files = county == 'all' ? Freecen1VldFile.order_by(dir_name: 1, file_name: 1).pluck(:id, :dir_name, :file_name, :num_entries) : Freecen1VldFile.where(dir_name: county).order_by(file_name: 1).pluck(:id, :dir_name, :file_name, :num_entries)

  vld_files.each do |vld_file|
    @needs_fix = false

    num_files += 1
    break if num_files > lim

    @vld_file_id = vld_file[0]
    @vld_chapman_code = vld_file[1]
    @vld_file_name = vld_file[2]
    @vld_num_entries = vld_file[3]

    @message_text = "Working on VLD File #{@vld_chapman_code} #{@vld_file_name} with #{@vld_num_entries} records"
    output_message(true, true)

    @this_enum = 'X'
    @this_civil_parish = 'XXXXXX'

    vld_entries = Freecen1VldEntry.where(freecen1_vld_file_id: @vld_file_id).order_by(enumeration_district: 1, civil_parish: 1).pluck(:enumeration_district, :civil_parish)

    vld_entries.each do |vld_entry|

      the_enum = vld_entry[0]
      the_civil_parish = vld_entry[1]

      new_enum_civil_parish = @this_enum != the_enum || @this_civil_parish != the_civil_parish ? true : false

      next if !new_enum_civil_parish || the_civil_parish.blank?

      update_records if fixit && @needs_fix

      @this_enum = the_enum
      @this_civil_parish = the_civil_parish

      @needs_fix = false
      @new_vld_civil_parish = @this_civil_parish

      # 1. look for all occurances of &

      look_for_ampersands

      # 2. look for all occurances of .

      look_for_dots

      # 3. then look for all occurances of ,

      look_for_commas

      # 4. then look for all occurances of 2 spaces

      look_for_extra_spaces

      @num_to_fix += 1 if @needs_fix == true
    end

    # Fix last enumeration district?
    update_records if fixit && @needs_fix

  end
  files_processed = lim < vld_file_count ? lim : vld_file_count
  time_end = Time.now.utc
  run_time = time_end - time_start
  file_processing_average_time = run_time / files_processed
  @message_text = "Processed #{files_processed} vld files"
  output_message(true, true)
  @message_text = "Needing fix #{@num_to_fix} issues"
  output_message(true, true)
  @message_text = "Fixed #{@num_fixed} issues"
  output_message(true, true)
  @message_text = "Average time to process a file #{file_processing_average_time.round(2)} secs"
  output_message(true, true)
  @message_text = "Run time = #{run_time.round(2)} secs"
  output_message(true, true)
  @message_text = "#{time_end.strftime('%d/%m/%Y %H:%M:%S')} Finished"
end

def look_for_ampersands
  find1 = (0...@new_vld_civil_parish.length).find_all { |i| @new_vld_civil_parish[i, 1] == '&' }
  if find1.length.positive?
    @needs_fix = true
    @message_text = "#{@new_vld_civil_parish} : found #{find1.length} ampersand(s)"
    output_message(false, true)
    @new_vld_civil_parish = @new_vld_civil_parish.gsub('&', ' and ')
  end
end

def look_for_dots
  find2 = (0...@new_vld_civil_parish.length).find_all { |i| @new_vld_civil_parish[i, 1] == '.' }
  if find2.length.positive?
    @needs_fix = true
    @message_text = "#{@new_vld_civil_parish}: found #{find2.length} dot(s)"
    output_message(false, true)
    @new_vld_civil_parish = @new_vld_civil_parish.gsub('.', ' ')
  end
end

def look_for_commas
  find2 = (0...@new_vld_civil_parish.length).find_all { |i| @new_vld_civil_parish[i, 1] == ',' }
  if find2.length.positive?
    @needs_fix = true
    @message_text = "#{@new_vld_civil_parish}: found #{find2.length} comma(s)"
    output_message(false, true)
    @new_vld_civil_parish = @new_vld_civil_parish.gsub(',', ' ')
  end
end

def look_for_extra_spaces
  fixed3 = @new_vld_civil_parish.strip.squeeze(' ')
  unless fixed3 == @new_vld_civil_parish
    @needs_fix = true
    @message_text = "#{@new_vld_civil_parish}: found multiple spaces"
    output_message(false, true)
    @new_vld_civil_parish = fixed3
  end
end

def output_message(write_to_log, write_to_file)
  p @message_text.to_s if write_to_log
  @message_file.puts @message_text.to_s if write_to_file
end

#update_records(@vld_chapman_code, @vld_file_id, @vld_file_name, @this_enum, @this_civil_parish, @new_vld_civil_parish, @num_fixed)

def update_records
  @message_text = "#{@vld_chapman_code} #{@vld_file_name} #{@this_enum} #{@this_civil_parish}: fixed_name: #{@new_vld_civil_parish}"
  output_message(false, true)

  num_vld_records_to_update = Freecen1VldEntry.where(freecen1_vld_file_id: @vld_file_id, enumeration_district: @this_enum, civil_parish: @this_civil_parish).count
  @message_text = " #{@vld_file_name} #{num_vld_records_to_update} vld records to update"
  output_message(false, true)

  vld_result = Freecen1VldEntry.collection.find({ freecen1_vld_file_id: @vld_file_id, enumeration_district: @this_enum, civil_parish: @this_civil_parish }).update_many({ '$set' => { 'civil_parish' => @new_vld_civil_parish } })

  num_dwelling_records_to_update = FreecenDwelling.where(freecen1_vld_file_id: @vld_file_id, enumeration_district: @this_enum, civil_parish: @this_civil_parish).count
  @message_text = "#{num_dwelling_records_to_update} dwelling records to update"
  output_message(false, true)

  dwelling_result = FreecenDwelling.collection.find({ freecen1_vld_file_id: @vld_file_id, enumeration_district: @this_enum, civil_parish: @this_civil_parish }).update_many({ '$set' => { 'civil_parish' => @new_vld_civil_parish } })

  @num_fixed += 1
end
