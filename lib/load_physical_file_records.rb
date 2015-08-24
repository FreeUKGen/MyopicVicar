class LoadPhysicalFileRecords
   
  def self.process(len,range)
  Mongoid.load!("#{Rails.root}/config/mongoid.yml")
  file_for_warning_messages = "log/add_physical_file_records.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
  message_file = File.new(file_for_warning_messages, "w")
  limit = len.to_i
  message_file.puts "Adding #{limit} batch record for #{range}"
  base_directory = Rails.application.config.datafiles
  change_directory = Rails.application.config.datafiles_changeset
  base_filenames = GetFiles.get_all_of_the_filenames(base_directory,range)
  change_filenames = GetFiles.get_all_of_the_filenames(change_directory,range)
  message_file.puts "#{base_filenames.length}\t base batches selected for processing\t#{change_filenames.length}\t change batches selected for processing\t"
  
  p "Processing change directory"
  process_batch = 0
  change_filenames.each do |file|
    process_batch = process_batch + 1
      break if process_batch == limit
    file_parts = file.split("/")
    file_name = file_parts[-1]
    possible_file = PhysicalFile.userid(file_parts[-2]).file_name(file_name).first
    if possible_file.nil?
      batch = PhysicalFile.new(:userid => file_parts[-2], :file_name => file_name, :change => true, :change_uploaded_date => File.mtime(file))
      unless batch.save
        message_file.puts "Batch number #{process_batch} #{file_name} for #{file_parts[-2]} was not saved"
      end
      sleep(Rails.application.config.sleep.to_f)
    else
      if possible_file.change
        possible_file.update_attribute(:change_uploaded_date, File.mtime(file)) unless possible_file.change_uploaded_date == File.mtime(file)
      else
        possible_file.update_attributes(:change => true, :change_uploaded_date => File.mtime(file))
      end
    end
  end
  message_file.puts "Processed #{process_batch}\t change batches into the database"

  p "Processing base directory"
  process_batch = 0
  missing = 0
  base_filenames.each do |file|
    process_batch = process_batch + 1
    break if process_batch == limit
    file_parts = file.split("/")
    file_name = file_parts[-1]
    possible_file = PhysicalFile.userid(file_parts[-2]).file_name(file_name).first
    if possible_file.nil?
      missing = missing + 1
      message_file.puts "Batch number #{process_batch} from the base collection #{file_name} for #{file_parts[-2]} was not in Batch collection"
      batch = PhysicalFile.new(:userid => file_parts[-2], :file_name => file_name, :base => true, :base_uploaded_date => File.mtime(file))
      batch.save
      sleep(Rails.application.config.sleep.to_f)
    else
      if possible_file.base
        possible_file.update_attribute(:base_uploaded_date, File.mtime(file)) unless possible_file.base_uploaded_date == File.mtime(file)
      else
        possible_file.update_attributes(:base => true, :base_uploaded_date => File.mtime(file))
      end
    end
  end
  message_file.puts "Processed #{process_batch} base batches and there were #{missing} extra batches in change and not in the base"
  
  p "Processing processed batches"
  process_batch = 0
  missing = 0
  Freereg1CsvFile.each do |file|
    process_batch = process_batch + 1
      break if process_batch == limit
    possible_file = PhysicalFile.userid(file.userid).file_name(file.file_name).first
    if possible_file.nil?
      missing = missing + 1
      missing = missing + 1
      message_file.puts "Batch number #{process_batch} #{file.file_name} for #{file.userid} was not in Batch collection"
      batch = PhysicalFile.new(:userid => file.userid, :file_name => file.file_name, :file_processed => true, :file_processed_date => file.updated_at)
      batch.save
      sleep(Rails.application.config.sleep.to_f)
    else
      if possible_file.file_processed
        possible_file.update_attribute(:file_processed_date, file.updated_at) unless possible_file.file_processed_date == file.updated_at
      else
         possible_file.update_attributes(:file_processed => true, :file_processed_date => file.updated_at)
      end
    end
  end
  message_file.puts "Processed #{process_batch}\t processed status into the database and there were #{missing} batches not in the change folder"

  end
end

