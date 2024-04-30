class PhysicalFile
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  require 'csv'
  field :file_name, type: String
  field :userid, type: String
  field :base,type: Boolean, default: false
  field :base_uploaded_date, type: DateTime
  field :change,type: Boolean, default: false
  field :change_uploaded_date, type: DateTime
  field :file_processed, type: Boolean, default: false
  field :file_processed_date, type: DateTime
  field :waiting_to_be_processed, type: Boolean, default: false
  field :waiting_date, type: DateTime
  field :action, type: String
  attr_accessor :type
  attr_accessor :county
  index ({ userid: 1, file_name: 1, base: 1, base_uploaded_date: 1})
  index ({ userid: 1, file_name: 1, file_processed: 1, file_processed_date: 1})
  index ({ base: 1})
  index ({file_processed: 1})
  index ({ waiting_to_be_processed: 1})
  index ({ userid: 1, waiting_to_be_processed: 1})
  class << self
    def id(id)
      where(:id => id)
    end
    def file_name(name)
      where(:file_name => name)
    end
    def processed
      where(:file_processed => true)
    end
    def not_processed
      where(:file_processed => false)
    end
    def not_uploaded_into_base
      where(:base => false)
    end
    def uploaded_into_base
      where(:base => true)
    end
    def change_uploaded_date(date)
      where(:change_uploaded_date => date)
    end
    def not_uploaded_into_change
      where(:change => false)
    end
    def uploaded_into_change
      where(:change => true)
    end
    def waiting
      where(:waiting_to_be_processed => true)
    end
    def not_waiting
      where(:waiting_to_be_processed => false)
    end
    def userid(id)
      where(:userid => id)
    end
    def remove_waiting_flag(id,file)
      batch = PhysicalFile.userid(id).file_name(file).first
      batch.update_attributes(waiting_to_be_processed: false, waiting_date: nil) if batch.present?
    end
    def remove_base_flag(id,file)
      batch = PhysicalFile.userid(id).file_name(file).first
      batch.update_attributes(:base => false, :base_uploaded_date => nil)  if batch.present?
    end

    def add_processed_flag(id,file)
      batch = PhysicalFile.userid(id).file_name(file).first
      batch.update_attributes(:file_processed => true) if batch.present?
    end

    def delete_document(userid,file_name)
      physical_file = PhysicalFile.userid(userid).file_name(file_name).first
      physical_file.destroy if physical_file.present?
    end

    def as_csv(batch,sorted,who,county)
      header = Array.new
      row = 0
      CSV.generate do |csv|
        PhysicalFile.attribute_names.each do |column_name|
          header << column_name if row == 0
          header <<  column_name unless  row == 0
          row = row + 1
        end
        explanation = "This was a selection based on "
        explanation = explanation + sorted
        explanation = explanation + " for " + who if who.respond_to?(:to_str)
        explanation = explanation + " in " + county if county.present?
        header << explanation
        csv <<  header
        case
        when batch.nil?
          message = 'No batches'
        when batch.length == 1
          row = row + 1
          csv << batch.first.attributes.values_at(*PhysicalFile.attribute_names)
        when batch.length > 1
          batch.each do |physical_file|
            row = row + 1
            csv << physical_file.attributes.values_at(*PhysicalFile.attribute_names)
          end
        end
      end
    end
  end

  def remove_base_flag
    self.update_attributes(:change => false, :change_uploaded_date => nil)
  end
  def remove_change_flag
    self.update_attributes(:change => false, :change_uploaded_date => nil)
  end
  def remove_processed_flag
    self.update_attributes(:file_processed =>false, :file_processed_date => nil)
  end
  def empty?
    file = false
    file = true if PhysicalFile.userid(self.userid).file_name(self.file_name).not_uploaded_into_base.not_uploaded_into_change.not_processed.not_waiting.exists?
    file
  end

  def add_file(batch)
    success = true
    if batch == "base" || batch == "reprocessing" && MyopicVicar::Application.config.template_set == 'freereg'
      self.update_attributes(:file_processed => false, :file_processed_date => nil,:waiting_to_be_processed => true, :waiting_date => Time.now)
    else
      p "why here"
    end
    case MyopicVicar::Application.config.template_set
    when 'freereg'
      #rake_lock_file = Rails.root.join('tmp', 'processing_rake_lock_file.txt')
      #if File.exist?(rake_lock_file)
        p 'i am here'
        #f = File.open(rake_lock_file)
        #locked = f.flock(File::LOCK_EX | File::LOCK_NB)
        #p "processor lock file: #{locked}"
        #unless locked == 0
         # logger.warn("FREEREG:CSV_PROCESSING: rake lock file #{rake_lock_file} already exists")
          pid1 = spawn("rake build:freereg_new_update[\"create_search_records\",\"waiting\",\"no\",\"a-9\"]")
          message = "The csv file #{ self.file_name} has been sent for processing . You will receive an email when it has been completed."
        #else
         # logger.warn("FREEREG:CSV_PROCESSING: Rake lock file exists but unlocked. Starting rake task for #{self.userid} #{self.file_name}")
          #pid1 = spawn("rake build:freereg_new_update[\"create_search_records\",\"waiting\",\"no\",\"a-9\"]")
          #message = "The csv file #{ self.file_name} is being processed . You will receive an email when it has been completed."
        #end
      #else
        #logger.warn("FREEREG:CSV_PROCESSING: Starting rake task for #{self.userid} #{self.file_name}")
        #pid1 = spawn("rake build:freereg_new_update[\"create_search_records\",\"waiting\",\"no\",\"a-9\"]")
        #message = "The csv file #{ self.file_name} is being processed . You will receive an email when it has been completed."
      #end
    when 'freecen'
      rake_lock_file = Rails.root.join('tmp', 'freecen_processing_rake_lock_file.txt')
      if File.exist?(rake_lock_file)
        logger.warn("FREECEN:CSV_PROCESSING: rake lock file #{rake_lock_file} already exists")
        message = "The csv file #{ self.file_name} has been sent for processing . You will receive an email when it has been completed."
      else

        logger.warn("FREECEN:CSV_PROCESSING: Starting rake task for #{self.userid} #{self.file_name}")
        pid1 = spawn("rake build:freecen_csv_process[\"no_search_records\",\"individual\",\"no\",\"#{File.join(userid, file_name)}\",\"Traditional\",\"Check(Warn)\"]")
        message = "The csv file #{ self.file_name} is being processed . You will receive an email when it has been completed."
        logger.warn("FREECEN:CSV_PROCESSING: #{pid1}")
      end
    end
    [success, message]
  end

  def add_file_change_of_owner(batch, type_of_processing)
    success = true
    if batch == "base" || batch == "reprocessing" && MyopicVicar::Application.config.template_set == 'freereg'
      self.update_attributes(:file_processed => false, :file_processed_date => nil,:waiting_to_be_processed => true, :waiting_date => Time.now)
    else
      p "#{batch} - processing type = #{type_of_processing}"
    end
    case MyopicVicar::Application.config.template_set
    when 'freereg'
      rake_lock_file = Rails.root.join('tmp', 'processing_rake_lock_file.txt')
      #if File.exist?(rake_lock_file)
        #logger.warn("FREEREG:CSV_PROCESSING: rake lock file #{rake_lock_file} already exists")
        pid1 = spawn("rake build:freereg_new_update[\"create_search_records\",\"waiting\",\"no\",\"a-9\"]")
        message = "The csv file #{ self.file_name} has been sent for processing . You will receive an email when it has been completed."
      #else
        #logger.warn("FREEREG:CSV_PROCESSING: Starting rake task for #{self.userid} #{self.file_name}")
        #pid1 = spawn("rake build:freereg_new_update[\"create_search_records\",\"waiting\",\"no\",\"a-9\"]")
        #message = "The csv file #{ self.file_name} is being processed . You will receive an email when it has been completed."
      #end
    when 'freecen'
      rake_lock_file = Rails.root.join('tmp', 'freecen_processing_rake_lock_file.txt')
      if File.exist?(rake_lock_file)
        logger.warn("FREECEN:CSV_PROCESSING: rake lock file #{rake_lock_file} already exists")
        message = "The csv file #{ self.file_name} has been sent for processing . You will receive an email when it has been completed."
      else

        logger.warn("FREECEN:CSV_PROCESSING: Starting rake task for #{self.userid} #{self.file_name}")
        pid1 = spawn("rake build:freecen_csv_process[\"no_search_records\",\"individual\",\"no\",\"#{File.join(userid, file_name)}\",\"Traditional\",\"#{type_of_processing}\"]")
        message = "The csv file #{ self.file_name} is being processed . You will receive an email when it has been completed."
        logger.warn("FREECEN:CSV_PROCESSING: #{pid1}")
      end
    end
    [success, message]
  end

  def file_and_entries_delete
    file = Freereg1CsvFile.where(file_name: file_name, userid: userid).first
    file.remove_from_ucf_list if file.present?
    Freereg1CsvFile.where(file_name: file_name, userid: userid).destroy_all if file.present?
    if file_name.present?
      base_file_location = File.join(Rails.application.config.datafiles, userid, file_name)
      File.delete(base_file_location) if File.file?(base_file_location)
    end
  end

  def freecen_csv_file_and_entries_delete(action_userid)
    file = FreecenCsvFile.where(file_name: file_name, userid: userid).first
    FreecenCsvFile.create_audit_record('Deleted', file, action_userid, file.freecen2_piece_id)
    FreecenCsvFile.where(file_name: file_name, userid: userid).destroy_all if file.present?
    if file_name.present?
      base_file_location = File.join(Rails.application.config.datafiles, userid, file_name)
      File.delete(base_file_location) if File.file?(base_file_location)
    end
  end

  def file_delete
    location = File.join(Rails.application.config.datafiles, self.userid, self.file_name)
    File.delete(location) if File.file?(location)
  end


  def update_userid(new_userid)
    self.update_attribute(:userid, new_userid)
  end


  def upload_report_data(start_date, end_date)
    start_date = format_date_for_report(start_date,'01/01/2020')
    end_date = format_date_for_report(end_date, Date.today)
    uploaded_files = PhysicalFile.where(c_at: @start_date..@end_date)
    uploaders_userid = uploaded_files.pluck(:userid).uniq.sort
    uploaders = UseridDetail.where(userid: {'$in' => uploaders_userid })
    uploders_role = uploaders.pluck(:person_role)
    uploaders_count = uploders_role.group_by(&:itself).transform_values(&:count)
    email_confirmed = UseridDetail.where(email_address_last_confirmned: @start_date..@end_date)
    users_count = UseridDetail.where(c_at: @start_date..@end_date)
    [uploaders_count, email_confirmed, users_count]
  end

  private

  def format_date_for_report date, default
    formatted_date = date.present? ? date.to_datetime : default.to_datetime
  end
end
