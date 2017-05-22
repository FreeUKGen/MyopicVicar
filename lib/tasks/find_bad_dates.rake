namespace :freereg do

  desc "Find bad UCF"
  task :find_bad_dates => [:environment] do

    file = File.join(Rails.root, 'script','dates.txt')
    output_file = File.new(file, "w")
    number_bad_dates = 0
    ChapmanCode.values.sort.each do |chapman_code|
      print "# #{chapman_code}\n"
      number = 0
      SearchRecord.no_timeout.where(:chapman_code => chapman_code).each_with_index do |record, i|
        number = number + 1
        print "#{number} records " if (number/10000)*10000 == number
        identified = false
        unless record.search_dates.include?(record.search_date)
          number_bad_dates = number_bad_dates + 1
          print "#\tBad date at #{record.freereg1_csv_entry_id}\n"
          output_file.puts "#{record.freereg1_csv_entry_id}\n"
          identified = true
        end
        
        if !identified && !record.secondary_search_date.blank?
          unless record.search_dates.include?(record.secondary_search_date)
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

