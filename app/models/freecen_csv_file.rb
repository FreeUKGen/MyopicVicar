# Copyright 2012 Trustees of FreeBMD
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class FreecenCsvFile
  include Mongoid::Document
  include Mongoid::Timestamps
  require "#{Rails.root}/app/uploaders/csvfile_uploader"
  require 'record_type'
  require 'name_role'
  require 'chapman_code'
  require 'userid_role'
  require 'register_type'
  require 'freecen_constants'
  require 'freecen_validations'
  require 'csv'
  # Fields correspond to cells in CSV headers
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # These field are there in the entry collection from the original files coming in as CSV file.
  # They are NOT USED we use the county and country from the Place collection the church_name from the church collection
  # and the register information from the register collection
  field :action, type: String
  field :field_specification, type: Hash
  field :chapman_code, type: String
  field :characterset, type: String
  field :country, type: String
  field :county, type: String # note in headers this is actually a Chapman code
  field :digest, type: String
  field :total_errors, type: Integer, default: 0
  field :total_warnings, type: Integer, default: 0
  field :total_info, type: Integer, default: 0
  field :file_digest, type: String
  field :file_errors, type: Array
  field :file_name, type: String
  field :flexible, type: Boolean, default: true
  field :locked_by_coordinator, type: Boolean, default: false
  field :locked_by_transcriber, type: Boolean, default: false
  field :modification_date, type: String, default: -> {'01 Jan 1998'}
  field :processed, type: Boolean, default: true
  field :processed_date, type: DateTime
  field :search_record_version, type: String
  field :series, type: String
  field :software_version, type: String
  field :total_records, type: Integer
  field :transcriber_email, type: String
  field :transcriber_name, type: String
  field :transcriber_syndicate, type: String
  field :transcription_date, type: String, default: -> {'01 Jan 1998'}
  field :uploaded_date, type: DateTime
  field :userid, type: String
  field :userid_lower_case, type: String
  field :year, type: String
  field :traditional, type: Integer
  field :header_line, type: Array


  index({ file_name: 1, userid: 1, county: 1, place: 1, register_type: 1 })
  index({ county: 1, place: 1, register_type: 1, record_type: 1 })
  index({ file_name: 1, file_errors: 1 })
  index({ error: 1, file_name: 1 })

  index({ userid: 1, uploaded_date: 1 }, { name: 'userid_uploaded_date' })
  index({ userid: 1, file_name: 1 }, { name: 'userid_file_name' })
  index({ county: 1, file_errors: 1 }, { name: 'county_errors' })
  # index({county: 1, datemin: 1}, {name: 'county_datemin'})

  before_save :add_lower_case_userid_to_file, :add_country_to_file
  #after_save :recalculate_last_amended, :update_number_of_files

  before_destroy do |file|
    file.save_to_attic
    FreecenCsvEntry.collection.delete_many(freecen_csv_file_id: file._id)
  end

  belongs_to :userid_detail, index: true, optional: true
  belongs_to :freecen2_piece, index: true, optional: true

  # register belongs to church which belongs to place

  has_many :batch_errors

  has_many :freecen_csv_entries, validate: false, order: :id.asc
  VALID_DAY = /\A\d{1,2}\z/
  VALID_MONTH = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP","SEPT", "OCT", "NOV", "DEC", "*","JANUARY","FEBRUARY","MARCH","APRIL","MAY","JUNE","JULY","AUGUST","SEPTEMBER","OCTOBER","NOVEMBER","DECEMBER"]
  VALID_YEAR = /\A\d{4}\z/
  ANOTHER_VALID_YEAR = /\A\d{2}\z/
  MONTHS = {
    'Jan' => '01',
    'Feb' => '02',
    'Mar' => '03',
    'Apr' => '04',
    'May' => '05',
    'Jun' => '06',
    'Jul' => '07',
    'Aug' => '08',
    'Sep' => '09',
    'Oct' => '10',
    'Nov' => '11',
    'Dec' => '12'
  }


  ###################################################################### class methods
  class << self

    def chapman_code(name)
      #note chapman is county in file
      where(:chapman_code => name)
    end

    def coordinator_lock
      where(:locked_by_coordinator => true)
    end

    def county(name)
      where(:county => name)
    end

    def errors
      where(:total_errors.gt => 0)
    end

    def file_name(name)
      where(:file_name => name)
    end

    def id(id)
      where(:id => id)
    end

    def syndicate(name)
      where(:transcriber_syndicate => name)
    end

    def transcriber_lock
      where(:locked_by_transcriber => true)
    end

    def userid(name)
      where(:userid => name)
    end

    def convert_date(date_field)
      #use a custom date conversion to number of days for comparison purposes only
      #dates provided vary in format
      date_day = 0
      date_month = 0
      date_year = 0
      unless date_field.nil?
        a = date_field.split(" ")
        case
        when a.length == 3
          #work with dd mmm yyyy
          #firstly deal with the dd
          date_day = a[0].to_i if(a[0].to_s =~ VALID_DAY)
          #deal with the month
          date_month = MONTHS[a[1]].to_i if (VALID_MONTH.include?(Unicode::upcase(a[1])) )
          #deal with the yyyy
          if a[2].length == 4
            date_year = a[2].to_i if (a[2].to_s =~ VALID_YEAR)
          else
            date_year = a[2].to_i if (a[2].to_s =~ ANOTHER_VALID_YEAR)
            date_year = date_year + 2000
          end

        when a.length == 2
          #deal with dates that are mmm yyyy firstly the mmm then the year
          date_month if (VALID_MONTH.include?(Unicode::upcase(a[0])))
          date_year if (a[1].to_s =~ VALID_YEAR)

        when a.length == 1
          #deal with dates that are year only
          date_year if (a[0].to_s =~ VALID_YEAR)

        end
      end
      my_days = date_year.to_i*365 + date_month.to_i*30 + date_day.to_i
      my_days
    end

    def delete_file(file)
      file.save_to_attic
      #first the entries
      FreecenCsvFile.where(userid: file.userid, file_name: file.file_name).all.each do |f|
        FreecenCsvEntry.delete_entries_for_a_file(f._id)
        f.delete unless f.nil?
      end
    end

    def file_update_location(file, param, session)
      if session[:selectcountry].blank? || session[:selectcounty].blank? || session[:selectplace].blank? ||  session[:selectchurch].blank? || param.blank? || param[:register_type].blank?
        message = FreecenCsvFile.file_update_location_message(session)
        return [false, "You are missing a selection of #{message}"]
      end
      place = FreecenCsvFile.file_update_location_location_parameters(session, param[:register_type])
      FreecenCsvFile.file_update_location_remove_from_original_register(file)
      file = FreecenCsvFile.file_update_location_update_fields(file, param, session, place, church, selected_register)
      FreecenCsvFile.file_update_location_clean_up(file, place, church)
      [true, '']
    end

    def file_update_location_clean_up(file, place)
      place.update_attribute(:data_present, true) unless place.data_present
      place.recalculate_last_amended_date

      file.propogate_file_location_change(place.id)
      PlaceCache.refresh_cache(place)
      file.update_freereg_contents_after_processing
    end

    def file_update_location_location_parameters(session, register_type)
      place = Freecen2Place.id(session[:selectplace]).first
    end

    def file_update_location_message(session)
      message = ""
      message = message + ": country" if session[:selectcountry].blank?
      message = message + ": county" if session[:selectcounty].blank?
      message = message + ": place" if session[:selectplace].blank?
      message
    end

    def file_update_location_remove_from_original_register(file)
      register = file.register
      register.freereg1_csv_files.delete(file)
      file.update_attribute(:register_id, nil)
      file.reload
      register.calculate_register_numbers
      church = register.church
      church.registers.delete(register) if register.records.to_i == 0
      register.destroy if register.records.to_i == 0
    end

    def file_update_location_update_fields(file, param, session, place, church, selected_register)
      file.place = place.place_name
      file.place_name = place.place_name
      file.church_name = church.church_name
      file.register_type = param[:register_type]
      file.county = session[:selectcounty]
      file.country = session[:selectcountry]
      file.alternate_register_name = church.church_name.to_s + " " + param[:register_type].to_s
      file.register_id = selected_register.id
      if session[:my_own]
        file.locked_by_transcriber = true
      else
        file.locked_by_coordinator = true
      end
      file.save
      file
    end

    def valid_freecen_csv_file?(freecen_csv_file)
      result = false
      return result if freecen_csv_file.blank?

      freecen_csv_file = FreecenCsvFile.find(freecen_csv_file)
      result = true if freecen_csv_file.present? && freecen_csv_file.freecen2_piece_id.present?
      logger.warn("FREEREG:LOCATION:VALIDATION invalid freecen_csv_file #{freecen_csv_file} ") unless result
      result
    end
  end # self

  # ######################################################################### instance methods

  def add_country_to_file
    # rspec tested during  csv processing
    chapman = self.chapman_code
    ChapmanCode::CODES.each_pair do |key, value|
      if value.has_value?(chapman)
        country = key
        self.country = key
        return
      end
    end
  end

  def add_lower_case_userid_to_file
    # rspec tested directly
    self[:userid_lower_case] = self[:userid].downcase
  end

  def add_to_rake_delete_freecen_csv_file_list
    #respected as part of remove batch
    processing_file = Rails.root.join(Rails.application.config.delete_list)
    File.open(processing_file, 'a') do |f|
      f.write("#{self.id},#{self.userid},#{self.file_name}\n")
    end
  end

  def are_we_changing_location?(param)
    change = false
    change = true unless param[:register_type] == self.register_type
    change = true unless param[:church_name] == self.church_name
    change = true unless param[:place] == self.place
    change
  end

  def augment_record_number_on_creation
    file_line_number = records.to_i + 1
    line_id = userid + '.' + file_name.upcase + '.' + file_line_number.to_s
    update_attributes(records: file_line_number)
    return file_line_number, line_id
  end

  def backup_file
    #this makes aback up copy of the file in the attic and creates a new one
    save_to_attic
    file_folder = File.join(Rails.application.config.datafiles, userid)
    file_location = File.join(Rails.application.config.datafiles, userid, file_name)
    success = false
    if File.exist?(file_folder)
      write_csv_file(file_location)
      success = true
    end
    success
  end

  def can_we_edit?
    result = PhysicalFile.userid(userid).file_name(file_name).waiting.blank? ? true : false
  end

  def change_owner_of_file(new_userid)
    # rspec tested
    # first step is to move the files
    result = [true, '']
    new_userid_folder_location = physical_userid_location(new_userid)
    old_userid_folder_location = physical_userid_location(userid)
    unless Dir.exist?(new_userid_folder_location)
      Dir.mkdir(new_userid_folder_location, 0774)
    end
    new_physical_file_location = physical_file_location(new_userid, file_name)
    write_csv_file(new_physical_file_location)
    if result[0]
      physical_file = PhysicalFile.new(userid: new_userid, file_name: file_name, base: true, base_uploaded_date: Time.new)
      physical_file.save
      physical_file.add_file('reprocessing')
    end
    result
  end

  def check_batch
    success = []
    success[0] = true
    success[1] = ''
    batch = self
    case batch
    when nil?
      success[0] = false
      success[1] = success[1] + "batch #{batch} does not exist"
    when file_name.blank?
      success[0] = false
      success[1] = success[1] + "batch name is missing #{batch} "
    when userid.blank?
      success[0] = false
      success[1] = success[1] + "batch userid is missing #{batch} "
    when record_type.blank?
      success[0] = false
      success[1] = success[1] + "batch record type is missing #{batch} "
    when freecen1_csv_entries.count.zero?
      success[0] = false
      success[1] = success[1] + "batch has no entries #{batch} "
    when freecen2_piece.blank?
      success[0] = false
      success[1] = success[1] + "batch has a null freecen_piece #{batch} "
    when freecen2_piece.freecen2_place.blank?
      success[0] = false
      success[1] = success[1] + "batch has a null place #{batch} "
    end
    success
  end

  def check_file
    success = []
    success[0] = true
    success[1] = ''
    FreecenCsvFile.file_name(file_name).userid(userid).each do |batch|
      case batch
      when nil?
        success[0] = false
        success[1] = success[1] + "file #{batch.file_name} does not exist"
      when file_name.blank?
        success[0] = false
        success[1] = success[1] + "file name is missing #{batch.file_name} "
      when userid.blank?
        success[0] = false
        success[1] = success[1] + "userid is missing #{batch.file_name} "
      when freecen_csv_entries.count.zero?
        success[0] = false
        success[1] = success[1] + "file has no entries #{batch.file_name} "
      when freecen2_piece.blank?
        success[0] = false
        success[1] = success[1] + "file has a null piece #{batch.file_name} "
      when freecen2_piece.present? && freecen2_piece.freecen2_place.blank?
        success[0] = false
        success[1] = success[1] + "file has a null place #{batch.file_name} "
      end
    end
    success
  end

  def check_locking_and_set(_param, sess)
    if sess[:my_own]
      update(locked_by_transcriber: true)
    else
      update(locked_by_coordinator: true)
    end
  end

  def clean_up
    update_statistics
  end

  def update_statistics
    update_number_of_files
    piece_id = freecen2_piece
    if piece_id.blank?
      logger.warn("FREECEN:#{id} does not belong to a piece ")
      return
    elsif place == piece_id.freereg2_place
      if place.blank?
        logger.warn("FREECEN:#{piece_id.id} does not belong to a place ")
        return
      end
    else
      place.recalculate_last_amended_date
    end
  end

  def define_colour
    # need to consider storing the processed rather than a look up
    if !total_errors.zero? && !locked_by_coordinator && !locked_by_transcriber
      color = 'color:red'
    elsif !processed
      color = 'color:orange'
    elsif total_errors.zero? && !locked_by_coordinator && !locked_by_transcriber
      color = 'color:green'
    elsif total_errors.zero? && (locked_by_coordinator || locked_by_transcriber)
      color = 'color:blue'
    elsif total_errors != 0 && (locked_by_coordinator || locked_by_transcriber)
      color = 'color:maroon'
    else
      color = 'color:black'
    end
    color
  end

  def determine_line_information(error_id)
    error_file = batch_errors.find(error_id)
    file_line_number = error_file.record_number if error_file.present?
    line_id = error_file.data_line[:line_id]
    [file_line_number, line_id]
  end

  def force_unlock
    batches = FreecenCsvFile.where(file_name: file_name, userid: userid).all
    batches.each do |batch|
      batch.update(locked_by_coordinator: false, locked_by_transcriber: false)
    end
  end

  def location_from_file
    my_piece = freecen2_piece
    my_place = my_piece.freereg2_place
    [my_place, my_piece]
  end

  def lock(type)
    batches = FreecenCsvFile.where(file_name: file_name, userid: userid).all
    set_transciber_lock = !locked_by_transcriber
    set_coordinator_lock = !locked_by_coordinator
    batches.each do |batch|
      if type
        # transcriber is changing their lock
        batch.update(locked_by_transcriber: set_transciber_lock)
      else
        # coordinator is changing locks
        batch.update(locked_by_coordinator: set_coordinator_lock)
        batch.update(locked_by_transcriber: false) unless set_coordinator_lock
      end
    end
  end

  def lock_all(type)
    batches = FreecenCsvFile.where(file_name: file_name, userid: userid).all
    batches.each do |batch|
      if type
        # transcriber is changing their lock
        batch.update(locked_by_transcriber: true)
      else
        # coordinator is changing locks
        batch.update(locked_by_coordinator: true)
      end
    end
  end

  def merge_batches
    batch_id = _id
    my_piece = freecen2_piece
    force_unlock
    added_records = 0
    my_piece.freecen_csv_files.each do |batch|
      if batch.userid == userid && batch.file_name == file_name
        unless batch._id == batch_id
          batch.freecen_csv_entries.each do |entry|
            added_records = added_records + 1
            entry.update(:freecen_csv_file_id, batch_id)
          end
          freecen2_piece.freecen_csv_files.delete(batch)
          batch.delete
        end
      end
    end
    # TODO need to recompute max, min and range
    unless added_records.zero?
      logger.info "FREECEN:update record count #{records.to_i} and #{added_records}"
      records = records.to_i + added_records
      update(records: records.to_s, locked_by_coordinator: true)
      logger.info "FREECEN:updated record count #{records.to_i} "
    end
    [true, '']
  end

  def physical_userid_location(userid)
    location = File.join(Rails.application.config.datafiles, userid)
  end

  def physical_file_location(userid, file_name)
    location = File.join(Rails.application.config.datafiles, userid, file_name)
  end

  def old_piece
    piece_id = freecen2_piece_id
    place_id = Freecen2Piece.find(piece_id).freecen2_place_id
  end

  def promulgate_userid_change(new_userid, old_userid)
    # since a file may have many batches we must change them all as we have moved the file
    new_userid_detail = UseridDetail.userid(new_userid).first
    FreecenCsvFile.userid(old_userid).file_name(file_name).each do |batch|
      success = FreecenCsvEntry.update_entries_userid(new_userid, batch)
      batch.update(userid: new_userid, userid_lower_case: new_userid.downcase, userid_detail_id: new_userid_detail.id) if success
    end
  end

  def recalculate_last_amended
    my_piece = freecen2_piece
    return if my_piece.blank?

    my_place = my_piece.freecen2_place
    return if my_place.blank?

    my_place.recalculate_last_amended_date
  end

  def save_to_attic
    # rspected with removal
    #Rails.logger.debug "Saving to attic"
    # to-do unix permissions
    file = file_name
    file_location = File.join(Rails.application.config.datafiles, userid, file)
    if File.file?(file_location)
      newdir = File.join(File.join(Rails.application.config.datafiles, userid), '.attic')
      Dir.mkdir(newdir) unless Dir.exist?(newdir)
      time = Time.now.to_i.to_s
      renamed_file = (file_location + '.' + time).to_s
      File.rename(file_location, renamed_file)
      FileUtils.mv(renamed_file, newdir, verbose: true)
      user = UseridDetail.where(userid: userid).first
      if user.present?
        attic_file = AtticFile.new(name: "#{file}.#{time}", date_created: DateTime.strptime(time, '%s'), userid_detail_id: user.id)
        attic_file.save
      end
    else
      Rails.logger.debug 'Nothing to save to attic'
    end
  end

  def remove_batch
    case
    when locked_by_transcriber || locked_by_coordinator
      return false, 'The removal of the batch was unsuccessful; the batch is locked'

    else
      # deal with file and its records
      add_to_rake_delete_freecen_csv_file_list
      save_to_attic
      delete
      # deal with the Physical Files collection
      PhysicalFile.delete_document(userid, file_name)
      [true, 'The removal of the batch entry was successful']
    end
  end

  def update_statistics_and_access(who_actioned)
    Rails.logger.debug 'update_statistics_and_access'
    self.locked_by_transcriber = true if who_actioned
    self.locked_by_coordinator = true unless who_actioned
    self.modification_date = Time.now.strftime("%d %b %Y")
    #recalculate_last_amended

    save

  end

  def update_number_of_files
    # this code although here and works produces values in fields that are no longer being used
    userid = UseridDetail.find_by(userid: userid)
    return if userid.blank?

    files = userid.freecen_csv_files
    if files.length.blank?
      number = 0
      records = 0
      last_uploaded = DateTime.new(1998, 1, 1)
    else
      number = files.length
      last_uploaded = DateTime.new(1998, 1, 1)
      records = 0
      files.each do |file|
        records = records + file.records.to_i
        last_uploaded = file.uploaded_date if last_uploaded.nil? || file.uploaded_date >= last_uploaded
      end
      userid.update(number_of_files: number, number_of_records: records, last_upload: last_uploaded)
    end
  end

  def update_freecen_piece
    Freecen2Piece.update_or_create_piece(self)
  end

  def calculate_transcriber_name(key)
    if record_type == key && userid_detail.present? && (userid_detail.person_surname.present? || userid_detail.person_forename.present?)
      answer, transcriber =  UseridDetail.can_we_acknowledge_the_transcriber(userid_detail)
      transcriber = nil unless answer
    end
    transcriber
  end

  def write_csv_file(file_location)
    CSV.open(file_location, 'wb', { row_sep: "\r\n" }) do |csv|
      csv << header_line
      records = freecen_csv_entries
      records.each do |rec|
        line = []
        line = add_fields(line, rec)
        csv << line
      end
    end
  end

  def write_spreadsheet_header(header)
    file_location = File.join(Rails.root, 'tmp', 'spreadersheet_header.csv')
    CSV.open(file_location, 'wb', { row_sep: "\r\n" }) do |csv|
      csv << header
    end
    file_location
  end

  def add_fields(line, rec)
    field_specification.values.each do |field|
      if Freecen::LOCATION.include?(rec[:data_transition])
        @entry = rec[field]
      elsif Freecen::LOCATION_PAGE.include?(rec[:data_transition])
        @entry = Freecen::LOCATION.include?(field) ? nil : rec[field]
      elsif Freecen::LOCATION_DWELLING.include?(rec[:data_transition])
        @entry = Freecen::LOCATION_PAGE.include?(field) ? nil : rec[field]
      else
        @entry = Freecen::LOCATION_DWELLING.include?(field) ? nil : rec[field]
      end
      line << @entry
    end
    line
  end
end
