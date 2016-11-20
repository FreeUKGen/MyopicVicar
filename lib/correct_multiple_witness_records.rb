class CorrectMultipleWitnessRecords
  require 'get_files'
  def self.process(limit,range,fix)
    fix == "fix" ? fix = true : fix = false
    range == 'all' ? file_selection = false : file_selection = true
    limit = limit.to_i 
      #The purpose of this clean up utility is to eliminate blank witness and duplicate witness entries in the database
    #to enable volume control we use the filenames as a means of selection
    file_for_warning_messages = "log/correct_witness_records.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, "w")
    message_file.puts "Correcting #{limit} witness record"
    p "Processing batches for #{range}"
    process_batch = 0
    num_witness = 0
    software_version = SoftwareVersion.control.first
    version = software_version.version unless software_version.nil?
    search_version  = software_version.last_search_record_version if software_version.present? && software_version.last_search_record_version.present?
    search_version = 1 if search_version.blank?
    p search_version
    if file_selection
      base_directory = Rails.application.config.datafiles
      filenames = GetFiles.get_all_of_the_filenames(base_directory,range) 
      processing = 0
      multiple_forenames = 0
      num_witnesses = 0
      num_marriages = 0
      start = Time.now
      corrected = 0
      p "There are #{filenames.length} files"     
      filenames.each do |filename|
        sleep_time = 20*(Rails.application.config.emmendation_sleep.to_f).to_f
        standalone_filename = File.basename(filename) 
        parent_dirname = File.dirname(File.dirname(filename))
        userid = File.dirname(filename).sub(parent_dirname, '').gsub(File::SEPARATOR, '')
        Freereg1CsvFile.where(userid: userid, file_name: standalone_filename, record_type: 'ma').all.each do |file|
          message_file.puts " #{file.userid} #{file.file_name}"
          p " #{file.userid} #{file.file_name}"
          process_batch = process_batch + 1
          break if process_batch == limit        
          witness_forenames = Array.new
          file.freereg1_csv_entries.no_timeout.each do |entry|
            witness_forenames = Array.new           
            if entry.record_type == 'ma'
              update_search_record = false 
              num_marriages = num_marriages + 1
              processing = processing + 1
               break if num_marriages == limit
               if entry.witness1_forename.present?
                 num_witnesses = num_witnesses + 1         
                 witness_forenames = entry.witness1_forename.split(" ")

                 if  witness_forenames.length >= 2
                   #we have a multiple forename
                   multiple_forenames =  multiple_forenames + 1                  
                   result = check_multiple_witness_forename_is_correct?(entry,entry.witness1_forename,entry.witness1_surname,witness_forenames,fix)
                   corrected = corrected + 1 unless result
                   update_search_record = true unless result
                 end
               end
               if entry.witness2_forename.present?
                 num_witnesses = num_witnesses + 1  
                 witness_forenames = entry.witness2_forename.split(" ")
                if  witness_forenames.length >= 2
                   #we have a multiple forename
                   multiple_forenames =  multiple_forenames + 1
                  result = check_multiple_witness_forename_is_correct?(entry,entry.witness2_forename,entry.witness2_surname,witness_forenames,fix)
                  corrected = corrected + 1 unless result
                  update_search_record = true unless result
                end
               end
               if update_search_record 
                 records = SearchRecord.where(freereg1_csv_entry_id:  entry.id)
                 if records.length > 1
                    message_file.puts "Multiple search records for #{entry.id}"
                 end
                 file = entry.freereg1_csv_file
                 if file.present?
                  result = ""
                  register = file.register if file.present?
                  church = register.church if register.present?
                  place = church.place if church.present?
                  result = SearchRecord.update_create_search_record(entry,search_version,place.id) if fix && place.present?
                  message_file.puts "result of update #{result}" unless result == 'updated'
                  sleep_time = (Rails.application.config.emmendation_sleep.to_f).to_f
                  sleep(sleep_time) if result == 'updated'
                else
                   message_file.puts "Missing file for #{entry.id}"
                 end
                  
                 records = SearchRecord.where(freereg1_csv_entry_id:  entry.id)
                if records.length > 1
                    message_file.puts "Multiple search records for #{entry.id}"
                end
               end
            end
            if processing == 10000
                processed_time = Time.now
                processing_time = (processed_time - start)*1000/num_marriages
                message_file.puts "#{num_marriages} marriages processed at a rate of #{processing_time} ms/marriage #{multiple_forenames} multiple forenames #{corrected} corrected"
                p  "#{num_marriages} marriages processed at a rate of #{processing_time} ms/marriage #{multiple_forenames} multiple forenames #{corrected} corrected"
                processing = 0
            end
          end
          message_file.puts "Processed #{file.userid} #{file.file_name} #{num_marriages} marriages #{num_witnesses} with witnesses #{multiple_forenames} multiple forenames and #{corrected} corrected"
          p "Processed #{file.userid} #{file.file_name} #{num_marriages} marriages #{num_witnesses} with witnesses #{multiple_forenames} multiple forenames and #{corrected} corrected"
          
        end
      end

    else
      processing = 0
      multiple_forenames = 0
      num_witnesses = 0
      num_marriages = 0
      start = Time.now
      corrected = 0
      witness_forenames = Array.new
      Freereg1CsvEntry.no_timeout.each do |entry|     
       
        if entry.record_type == 'ma'
          update_search_record = false 
          num_marriages = num_marriages + 1
          processing = processing + 1
           break if num_marriages == limit
           if entry.witness1_forename.present?
             num_witnesses = num_witnesses + 1         
             witness_forenames = entry.witness1_forename.split(" ")
             if  witness_forenames.length >= 2
               if witness_forenames.length >= 3
                message_file.puts entry.id
                message_file.puts witness_forenames
               end
               #we have a multiple forename
               multiple_forenames =  multiple_forenames + 1
               result = check_multiple_witness_forename_is_correct?(entry,entry.witness1_forename,entry.witness1_surname,witness_forenames,fix)
               corrected = corrected + 1 unless result
               update_search_record = true unless result
             end
           end
           if entry.witness2_forename.present?
             num_witnesses = num_witnesses + 1  
             witness_forenames = entry.witness2_forename.split(" ")
            
            if  witness_forenames.length >= 2
               if witness_forenames.length >= 3
                 message_file.puts entry.id
                  message_file.puts witness_forenames
               end
              
               #we have a multiple forename
               multiple_forenames =  multiple_forenames + 1
              result = check_multiple_witness_forename_is_correct?(entry,entry.witness2_forename,entry.witness2_surname,witness_forenames,fix)
              corrected = corrected + 1 unless result
              update_search_record = true unless result
            end
           end
           if update_search_record && fix
             file = entry.freereg1_csv_file
             if file.present?
              result = ""
                register = file.register if file.present?
                church = register.church if register.present?
                place = church.place if church.present?
                result = SearchRecord.update_create_search_record(entry,search_version,place.id) if fix && place.present?
                message_file.puts "result of update #{result}"
             end
           end
        end
        if processing == 10000
            processed_time = Time.now
            processing_time = (processed_time - start)*1000/num_marriages
            message_file.puts "#{num_marriages} marriages processed at a rate of #{processing_time} ms/marriage #{multiple_forenames} multiple forenames #{corrected} corrected"
            p  "#{num_marriages} marriages processed at a rate of #{processing_time} ms/marriage #{multiple_forenames} multiple forenames #{corrected} corrected"
            processing = 0
          end
      end
    end
    message_file.puts "Processed #{num_marriages} marriages #{num_witnesses} with witnesses #{multiple_forenames} multiple forenames and #{corrected} corrected" 
    p  "Processed #{num_marriages} marriages #{num_witnesses} with witnesses #{multiple_forenames} multiple forenames and #{corrected} corrected" 
  end
  def self.check_multiple_witness_forename_is_correct?(entry,witness_forename,witness_surname,witness_forenames,fix)   
    result = true    
    entry.multiple_witnesses.each do |multiple_witness|  
      if witness_forenames[0] == multiple_witness.witness_forename && witness_forenames[1] == multiple_witness.witness_surname
        multiple_witness.update_attributes(:witness_forename => witness_forename, :witness_surname => witness_surname) if fix
        result = false 
      end  
    end
    return result
  end
end
