class Csvfile < CarrierWave::Uploader::Base
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  field :userid, type: String
  field :file_name, type: String
  field :process, type: String, default: 'Process tonight'
  field :type_of_field, type: String, default: 'Traditional' # CEN
  field :type_of_processing, type: String, default: 'No POB Warnings' # CEN
  field :action, type: String
  # files are stored in Rails.application.config.datafiles
  mount_uploader :csvfile, CsvfileUploader

  def check_for_existing_file_and_save
    # this saves the exiting file in the attic
    process = true
    batch = PhysicalFile.where(userid: userid, file_name: file_name, base: true).first
    if batch.present?
      file_location = File.join(Rails.application.config.datafiles, userid, file_name)
      if File.file?(file_location)
        newdir = File.join(File.join(Rails.application.config.datafiles, userid), '.attic')
        Dir.mkdir(newdir) unless Dir.exists?(newdir)
        time = Time.now.to_i.to_s
        renamed_file = (file_location + '.' + time).to_s
        File.rename(file_location, renamed_file)
        FileUtils.mv(renamed_file, newdir, verbose: true)
        FileUtils.rm(file_location) if File.file?(file_location)
        user = UseridDetail.where(userid: userid).first
        if user.present?
          attic_file = AtticFile.new(name: "#{file_name}.#{time}", date_created: DateTime.strptime(time, '%s'), userid_detail_id: user.id)
          attic_file.save
        end
      end
    end
    process
  end

  def check_name(name)
    decision = false
    decision = true if file_name == name
    decision
  end

  def clean_up
    batch = PhysicalFile.find_by(userid: userid, file_name: file_name, base: true)
    file_name_parts = file_name.split('.')
    old_file_name = file_name_parts[0] + '.' + file_name_parts[1].upcase
    new_file_name = file_name_parts[0] + '.' + file_name_parts[1].downcase
    old_file_location = File.join(Rails.application.config.datafiles, userid, old_file_name)
    new_file_location = File.join(Rails.application.config.datafiles, userid, new_file_name)
    File.delete(old_file_location) if File.file?(old_file_location)
    File.delete(new_file_location) if File.file?(new_file_location)
    batch.delete if batch.present?
  end

  def create_batch_unless_exists
    batch = PhysicalFile.where(userid: userid, file_name: file_name).first
    if batch.present?
      batch.update_attributes(base: true, base_uploaded_date: Time.now, file_processed: false)
    else
      batch = PhysicalFile.new(userid: userid, file_name: file_name, base: true, base_uploaded_date: Time.now, file_processed: false)
      batch.save
    end
    batch
  end

  def downcase_extension
    file_name_parts = file_name.split('.')
    file_name_parts[1] = file_name_parts[1].downcase
    new_file_name = file_name_parts[0] + '.' + file_name_parts[1]
    new_file_name
  end

  def rename_extention
    file_name_parts = file_name.split('.')
    old_file_name = file_name_parts[0] + '.' + file_name_parts[1].upcase
    new_file_name = file_name_parts[0] + '.' + file_name_parts[1].downcase
    old_file_location = File.join(Rails.application.config.datafiles, userid, old_file_name)
    new_file_location = File.join(Rails.application.config.datafiles, userid, new_file_name)
    File.rename(old_file_location, new_file_location) if File.exist?(old_file_location)
  end

  def estimate_time
    size = 1
    place = File.join(Rails.application.config.datafiles, userid, file_name)
    size = File.size(place)
    unit = 0.001
    processing_time = (size.to_i * unit).to_i
    processing_time
  end

  def estimate_size
    place = File.join(Rails.application.config.datafiles, userid, file_name)
    size = File.size?(place)
    size
  end

  def physical_file_for_user_exists
    file_name_parts = file_name.split('.')
    old_file_name = file_name_parts[0] + '.' + file_name_parts[1].upcase
    new_file_name = file_name_parts[0] + '.' + file_name_parts[1].downcase
    old_file_location = File.join(Rails.application.config.datafiles, userid, old_file_name)
    new_file_location = File.join(Rails.application.config.datafiles, userid, new_file_name)
    return true if File.exist?(old_file_location) || File.exist?(new_file_location)

    false
  end

  def process_the_batch(user)
    proceed = check_for_existing_file_and_save
    save if proceed

    message = "The upload with file name #{file_name} was unsuccessful because #{errors.messages}" if errors.any?
    return [false, message] if errors.any?

    rename_extention if MyopicVicar::Application.config.template_set == 'freecen'
    batch = create_batch_unless_exists
    range = File.join(userid, file_name)
    batch_processing = PhysicalFile.where(userid: userid, file_name: file_name, waiting_to_be_processed: true).exists?
    message = 'Your file is already waiting to be processed. It cannot be reprocessed until that one is finished' if batch_processing.present?
    return [false, message] if batch_processing.present?

    size = estimate_size
    if size.blank? || size.present? && size < 100
      proceed = false
      message = "The file #{file_name} either does not exist or is too small to be a valid file."
      clean_up
      return [proceed, message]
    end

    processing_time = estimate_time
    case MyopicVicar::Application.config.template_set
    when 'freereg'
      if user.person_role == 'trainee'
        pid1 = Kernel.spawn("rake build:freereg_new_update[\"no_search_records\",\"individual\",\"no\",#{range}]")
        message = "The csv file #{file_name} is being checked. You will receive an email when it has been completed."
        process = true
      elsif processing_time < 600
        batch.update_attributes(waiting_to_be_processed: true, waiting_date: Time.now)
        rake_lock_file = File.join(Rails.root, 'tmp', 'processing_rake_lock_file.txt')
        processor_initiation_lock_file = File.join(Rails.root, 'tmp', 'processor_initiation_lock_file.txt')
        #if File.exist?(processor_initiation_lock_file)
         # message = "The csv file #{file_name} has been sent for processing . You will receive an email when it has been completed."
        #else
          initiation_locking_file = File.new(processor_initiation_lock_file, 'w') unless File.exist?(processor_initiation_lock_file)
          pid1 = Kernel.spawn("rake build:freereg_new_update[\"create_search_records\",\"waiting\",\"no\",\"a-9\"]")
          message = "The csv file #{file_name} is being processed . You will receive an email when it has been completed."
        #end
        process = true
      elsif processing_time >= 600
        batch.destroy #update_attributes(base: true, base_uploaded_date: Time.now, file_processed: false)
        message = "Your file #{file_name} is not being processed in its current form as it is too large. Your coordinator and the data managers have been informed. Please discuss with them how to proceed. "
        UserMailer.report_to_data_manger_of_large_file(file_name, userid).deliver_now
        process = false
      end
    when 'freecen'
      batch.update_attributes(waiting_to_be_processed: true, waiting_date: Time.now)
      logger.warn("FREECEN:CSV_PROCESSING: Starting rake task for #{userid} #{file_name}")
      pid1 =  spawn("rake build:freecen_csv_process[\"no_search_records\",\"individual\",\"no\",\"#{range}\",\"'Modern'\",\"#{type_of_processing}\"]")
      message = "The csv file #{file_name} is being checked. You will receive an email when it has been completed."
      logger.warn("FREECEN:CSV_PROCESSING: rake task for #{pid1}")
      process = true
    end
    #raise ([process, message]).inspect
    [process, message]
  end

  def setup_batch_on_replace(original_file_name)
    return false, 'The file you are replacing must have the same name' unless check_name(original_file_name)

    proceed = true
    proceed = physical_file_for_user_exists
    #lets check that the file has indeed been processed previously.
    PhysicalFile.where(userid: userid, file_name: file_name).exists? ? batch_entries_present = true : batch_entries_present = false
    if !proceed
      message = 'You are attempting to replace a file you do not have. Likely you are a coordinator replacing a file belonging to someone else. You must replace into their userid.'

    elsif Freereg1CsvFile.userid(userid).file_name(file_name).transcriber_lock.exists?
      message = 'You have done on-line edits to the file, so it is locked against replacement until you have downloaded the file.'
      proceed = false

    elsif Freereg1CsvFile.userid(userid).file_name(file_name).coordinator_lock.exists?
      message = 'The file you are trying to replace has been locked by your coordinator.'
      proceed = false

    elsif !batch_entries_present
      batch = PhysicalFile.new(base: true, base_uploaded_date: Time.now, file_processed: false, userid: userid , file_name: file_name)
      batch.save
      message = ''
    elsif batch_entries_present
      batch = PhysicalFile.find_by(userid: userid, file_name: file_name)
      batch.update_attributes(base: true, base_uploaded_date: Time.now, file_processed: false)
      message = ''
    else
      message = 'A situation has occurred that should not have. Please have your coordinator contact system administration.'
      proceed = false
    end
    [proceed, message]
  end

  def setup_batch_on_upload
    proceed = true
    message = ''
    if PhysicalFile.userid(userid).file_name(file_name).first.present?
      proceed = false
      message = 'You cannot upload a file with the same name as one you have already uploaded. You must use the REPLACE option.'
    end
    [proceed, message]
  end
end
