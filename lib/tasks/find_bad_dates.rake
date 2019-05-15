namespace :freereg do

  desc "Find bad UCF"
  task :find_bad_dates => [:environment] do

    output_directory = File.join(Rails.root, 'script')

    ChapmanCode.values.sort.each do |chapman_code|
      print "# #{chapman_code}\n"
      SearchRecord.no_timeout.where(:chapman_code => chapman_code).each_with_index do |record, i|
        identified = false
        unless record.search_dates.include?(record.search_date)
          print "#\tBad date at #{i}\n"
          print "#{record.freereg1_csv_entry_id}\n"
          identified = true
        end
        
        if !identified && !record.secondary_search_date.blank?
          unless record.search_dates.include?(record.secondary_search_date)
            print "#\tBad secondary date at #{i}\n"
            print "#{record.freereg1_csv_entry_id}\n"
            identified = true
          end          
        end
      end      
    end
    

  end
end

