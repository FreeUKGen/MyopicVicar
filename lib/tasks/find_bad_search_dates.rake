namespace :freereg do

  desc "Find bad UCF"
  task :find_bad_search_dates,[:limit] => [:environment] do |t, args|

    file = File.join(Rails.root, 'script','search_dates.txt')
    output_file = File.new(file, "w")
    number_bad_dates = 0
    number = 0
    stop_after = args.limit.to_i
    ChapmanCode.values.sort.each do |chapman_code|
      print "# #{chapman_code}\n"
      SearchRecord.no_timeout.where(:chapman_code => chapman_code).each_with_index do |record, i|
        break if number > stop_after 
        number = number + 1
        print "#{number} records #{number_bad_dates}\n" if (number/10000)*10000 == number
        entry_id = record.freereg1_csv_entry_id
        entry = Freereg1CsvEntry.find(entry_id)
        identified = false
          entry_dates = Array.new
          entry_dates << entry.birth_date unless entry.birth_date.blank?
          entry_dates << entry.baptism_date unless entry.baptism_date.blank?
          entry_dates << entry.burial_date unless entry.burial_date.blank?
          entry_dates << entry.marriage_date unless entry.marriage_date.blank?
          if entry_dates.length > 0
            unless entry_dates.include?(record.search_date)
              number_bad_dates = number_bad_dates + 1
              print "#\tBad date at #{record.freereg1_csv_entry_id}\n"
              p "#{record.search_date}, #{entry_dates}"
              output_file.puts "#{record.freereg1_csv_entry_id}\n"
              identified = true
            end
          end 
       
        
        if !identified && !record.secondary_search_date.blank?
          unless record.secondary_search_date == entry.birth_date || record.secondary_search_date == entry.baptism_date
            print "#\tBad secondary date at #{record.freereg1_csv_entry_id}\n"
             output_file.puts "#{record.freereg1_csv_entry_id}\n"
            identified = true
          end          
        end
      end      
    end
    print "Finished with #{number_bad_dates} bad dates"

  end
end

