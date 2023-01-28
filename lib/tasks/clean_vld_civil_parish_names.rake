task :clean_vld_civil_parish_names, [:chapman_code, :file_limit, :fix] => [:environment] do |t, args|
  p "Started clean_vld_civil_parish_names #{args.chapman_code}  #{args.file_limit} #{args.fix}"
  clean_name(args.chapman_code, args.file_limit, args.fix)
  p 'Finished'
end

def clean_name(chapman_code, file_limit, fix)
  time_start = Time.now.utc
  num_files = 0
  fixed = 0
  needing_fix = 0
  county = chapman_code.to_s.downcase == 'all' ? 'all' : chapman_code.to_s
  lim = file_limit.to_i
  fixit = fix.to_s.downcase == 'y' ? true : false
  p "#{time_start.strftime('%d/%m/%Y %H:%M:%S')} County=#{county} file_limit=#{lim} fixit=#{fixit}"

  file_for_warning_messages = "log/clean_vld_civil_parish_names_#{county}_#{time_start.strftime("%Y%m%d%H%M%S")}.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  message_file = File.new(file_for_warning_messages, 'w')

  vld_file_count = county == 'all' ? Freecen1VldFile.count : Freecen1VldFile.where(dir_name: county).count
  scope = county == 'all' ? 'All counties have' : "#{county} has"
  p "#{scope} #{vld_file_count} files"

  vld_files = county == 'all' ? Freecen1VldFile.order_by(dir_name: 1, file_name: 1).pluck(:id, :dir_name, :file_name, :num_entries) : Freecen1VldFile.where(dir_name: county).order_by(file_name: 1).pluck(:id, :dir_name, :file_name, :num_entries)

  vld_files.each do |vld_file|

    num_files += 1
    break if num_files > lim

    vld_file_id = vld_file[0]
    vld_chapman_code = vld_file[1]
    vld_file_name = vld_file[2]
    vld_num_entries = vld_file[3]

    message_text = "Working on VLD File  #{vld_chapman_code} #{vld_file_name } with #{vld_num_entries} records"
    p message_text
    message_file.puts "#{message_text}"


    vld_entries = Freecen1VldEntry.where(freecen1_vld_file_id: vld_file_id).pluck(:id, :civil_parish)

    vld_entries.each do |vld_entry|

      vld_entry_id = vld_entry[0]
      vld_civil_parish = vld_entry[1]


      find1 = [] # 1. look for all occurances of &
      find2 = [] # 2. look for all occurances of ,

      unless vld_civil_parish .blank?

        needs_fix = false

        # 1. look for all occurances of &

        find1 = (0...vld_civil_parish .length).find_all { |i| vld_civil_parish [i, 1] == '&' }

        if find1.length.positive?
          needs_fix = true
          fixed1 = vld_civil_parish .gsub('&', ' and ')
          message_text = "#{vld_entry_id} #{vld_chapman_code} #{vld_civil_parish} : found #{find1.length} ampersand(s)"
          message_file.puts "#{message_text}"
        else
          fixed1 = vld_civil_parish
        end

        # 2. look for all occurances of ,

        find2 = (0...fixed1.length).find_all { |i| fixed1[i, 1] == ',' }

        if find2.length.positive?
          needs_fix = true
          fixed2 = fixed1.gsub(',', ' ')
          message_text = "#{vld_entry_id} #{vld_chapman_code} #{vld_civil_parish}: found #{find2.length} comma(s)"
          message_file.puts "#{message_text}"
        else
          fixed2 = fixed1
        end

        # 3. then look for all occurances of 2 spaces

        fixed3 = fixed2.strip.squeeze(' ')
        unless fixed3 == fixed2
          needs_fix = true
          message_text = "#{vld_entry_id} #{vld_chapman_code} #{vld_civil_parish}: found multiple spaces"
          message_file.puts "#{message_text}"
        end
        needing_fix += 1 if needs_fix == true

        # Fix
        if fixit && needs_fix

          new_vld_civil_parish  = fixed3
          message_text = "#{vld_entry_id} #{vld_chapman_code} #{vld_civil_parish }: fixed_name: #{new_vld_civil_parish}"
          message_file.puts "#{message_text}"

          record_to_update = Freecen1VldEntry.where(id: vld_entry_id)

          #AEV01 record_to_update.update(civil_parish: new_vld_civil_parish)

          fixed += 1
        end
      end
    end
  end
  files_processed = lim < vld_file_count ? lim : vld_file_count
  time_end = Time.now.utc
  run_time = time_end - time_start
  file_processing_average_time = run_time / files_processed
  p "Processed #{files_processed} vld files"
  p "Needing fix #{needing_fix} records"
  p "Fixed #{fixed}"
  p "Average time to process a file #{file_processing_average_time.round(2)} secs"
  p "Run time = #{run_time.round(2)} secs"
  p "#{time_end.strftime('%d/%m/%Y %H:%M:%S')} Finished"
end
