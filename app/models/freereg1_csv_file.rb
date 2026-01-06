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

class Freereg1CsvFile
  include Mongoid::Document
  include Mongoid::Timestamps
  require "#{Rails.root}/app/uploaders/csvfile_uploader"
  require 'record_type'
  require 'name_role'
  require 'chapman_code'
  require 'userid_role'
  require 'register_type'
  require 'freereg_validations'
  require 'csv'
  # Fields correspond to cells in CSV headers
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # These field are there in the entry collection from the original files coming in as CSV file.
  # They are NOT USED we use the county and country from the Place collection the church_name from the church collection
  # and the register information from the register collection
  field :country, type: String
  field :county, type: String # note in headers this is actually a Chapman code
  field :chapman_code,  type: String
  field :church_name, type: String
  field :register_type, type: String
  field :record_type, type: String # , :in => RecordType::ALL_TYPES+[nil]
  validates_inclusion_of :record_type, in: RecordType::ALL_FREEREG_TYPES + [nil]
  #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  field :place, type: String
  field :place_name, type: String
  field :records, type: String
  field :datemin, type: String
  field :datemax, type: String
  field :zero_entries, type: Boolean, default: false
  field :daterange, type: Array
  field :userid, type: String
  field :userid_lower_case, type: String
  field :file_name, type: String
  field :transcriber_name, type: String
  field :transcriber_email, type: String
  field :transcribed_by, type: String
  field :transcriber_syndicate, type: String
  field :credit_email, type: String
  field :credit_name, type: String
  field :first_comment, type: String
  field :second_comment, type: String
  field :transcription_date, type: String, default: -> {'01 Jan 1998'}
  field :modification_date, type: String, default: -> {'01 Jan 1998'}
  field :uploaded_date, type: DateTime
  field :error, type: Integer, default: 0
  field :digest, type: String
  field :locked_by_transcriber, type: Boolean, default: false
  field :locked_by_coordinator, type: Boolean, default: false
  field :lds, type: String, default: 'no'
  field :action, type: String
  field :characterset, type: String
  field :alternate_register_name, type: String
  field :csvfile, type: String
  field :processed, type: Boolean, default: true
  field :processed_date, type: DateTime
  field :def, type: Boolean, default: false
  field :order, type: Hash
  field :software_version, type: String
  field :search_record_version, type: String
  field :ucf_list, type: Array
  field :ucf_updated, type: DateTime

  index({ file_name: 1, userid: 1, county: 1, place: 1, church_name: 1, register_type: 1 })
  index({ county: 1, place: 1, church_name: 1, register_type: 1, record_type: 1 })
  index({ file_name: 1, error: 1 })
  index({ error: 1, file_name: 1 })

  index({ userid: 1, uploaded_date: 1 }, { name: 'userid_uploaded_date' })
  index({ userid: 1, file_name: 1 }, { name: 'userid_file_name' })
  index({ county: 1, errors: 1 }, { name: 'county_errors' })
  # index({county: 1, datemin: 1}, {name: 'county_datemin'})

  before_save :add_lower_case_userid_to_file, :add_country_to_file, :check_register_type
  after_save :recalculate_last_amended, :update_number_of_files

  before_destroy do |file|
    file.save_to_attic
    Freereg1CsvEntry.where(:freereg1_csv_file_id => file._id).destroy_all
  end

  belongs_to :register, index: true
  belongs_to :userid_detail, index: true, optional: true

  # register belongs to church which belongs to place

  has_many :batch_errors

  has_many :freereg1_csv_entries, validate: false, order: :id.asc
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
      where(:county => name)
    end

    def church_name(name)
      where(:church_name => name)
    end

    def coordinator_lock
      where(:locked_by_coordinator => true)
    end

    def county(name)
      where(:county => name)
    end

    def datemin(date)
      where(datemin: date)
    end

    def errors
      where(:error.gt => 0)
    end

    def file_name(name)
      where(:file_name => name)
    end

    def id(id)
      where(:id => id)
    end

    def place(name)
      where(:place => name)
    end

    def record_type(name)
      where(:record_type => name)
    end

    def register_type(name)
      where(:register_type => name)
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

    def calculate_min_year(entries)
      datemin = FreeregValidations::YEAR_MAX.to_i
      zero_entries = false
      entries.each do |entry|
        if entry.year.blank?
          zero_entries = true
          next
        else
          datemin = entry.year.to_i if ((entry.year.to_i < datemin))
        end
      end
      [datemin, zero_entries]
    end

    def calculate_max_year(entries)
      datemax = FreeregValidations::YEAR_MIN.to_i
      entries.each do |entry|
        next if entry.year.blank?
        datemax = entry.year.to_i if entry.year.to_i > datemax
      end
      datemax
    end

    def calculate_range_distribution(entries)
      number_of_records = 0
      daterange = Array.new(50,0)
      entries.each do |entry|
        xx = entry.year
        if xx.present? && entry.enough_name_fields?
          xx = xx.to_i
          bin = ((xx-FreeregOptionsConstants::DATERANGE_MINIMUM) / 10).to_i
          bin = 0 if bin < 0
          bin = 49 if bin > 49
          daterange[bin] = daterange[bin] + 1
        end
        number_of_records = number_of_records + 1
      end
      return number_of_records, daterange
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
      Freereg1CsvFile.where(:userid  => file.userid, :file_name => file.file_name).all.each do |f|
        Freereg1CsvEntry.delete_entries_for_a_file(f._id)
        f.delete unless f.nil?
      end
    end

    def delete_userid_folder(userid)
      folder_location = File.join(Rails.application.config.datafiles,userid)
      FileUtils.rm_rf(folder_location) if Dir.exist?(folder_location)
    end

    def file_update_location(file, param, session)
      if session[:selectcountry].blank? || session[:selectcounty].blank? || session[:selectplace].blank? ||  session[:selectchurch].blank? || param.blank? || param[:register_type].blank?
        message = Freereg1CsvFile.file_update_location_message(session)
        return [false, "You are missing a selection of #{message}"]
      end
      place, church, selected_register = Freereg1CsvFile.file_update_location_location_parameters(session, param[:register_type])
      Freereg1CsvFile.file_update_location_remove_from_original_register(file)
      file = Freereg1CsvFile.file_update_location_update_fields(file, param, session, place, church, selected_register)
      Freereg1CsvFile.file_update_location_clean_up(file, place, church)
      [true, '']
    end

    def file_update_location_clean_up(file, place, church)
      place.update_attribute(:data_present, true) unless place.data_present
      place.recalculate_last_amended_date
      church.update_attribute(:place_name, place.place_name)
      file.propogate_file_location_change(place.id)
      PlaceCache.refresh_cache(place)
      file.update_freereg_contents_after_processing
    end

    def file_update_location_location_parameters(session, register_type)
      place = Place.id(session[:selectplace]).first
      church = Church.id(session[:selectchurch]).first
      selected_register = nil
      church.registers.each do |register|
        selected_register = register if register.register_type == register_type
      end
      if selected_register.blank?
        selected_register = Register.create(register_type: register_type, church_id: church.id, alternate_register_name: (church.church_name.to_s + " " + register_type.to_s))
      end
      [place, church, selected_register]
    end

    def file_update_location_message(session)
      message = ""
      message = message + ": country" if session[:selectcountry].blank?
      message = message + ": county" if session[:selectcounty].blank?
      message = message + ": place" if session[:selectplace].blank?
      message = message + ": church" if session[:selectchurch].blank?
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

    def unique_names(names)
      names["bu"]['transcriber_name'] = names["bu"]['transcriber_name'].uniq unless names["bu"]['transcriber_name'].nil?
      names["bu"]['credit_name'] = names["bu"]['credit_name'].uniq  unless names["bu"]['credit_name'].nil?
      names["ba"]['transcriber_name'] = names["ba"]['transcriber_name'].uniq unless names["ba"]['transcriber_name'].nil?
      names["ba"]['credit_name'] = names["ba"]['credit_name'].uniq unless names["ba"]['credit_name'].nil?
      names["ma"]['transcriber_name'] = names["ma"]['transcriber_name'].uniq unless names["ma"]['transcriber_name'].nil?
      names["ma"]['credit_name'] = names["ma"]['credit_name'].uniq unless names["ma"]['credit_name'].nil?
      if names["bu"]['transcriber_name'].present? && names["bu"]['credit_name'].present?
        names["bu"]['transcriber_name'].each do |name|
          names["bu"]['credit_name'].delete_if { |x| x == name}
        end
      end
      if names["ma"]['transcriber_name'].present? && names["ma"]['credit_name'].present?
        names["ma"]['transcriber_name'].each do |name|
          names["ma"]['credit_name'].delete_if { |x| x == name}
        end
      end
      if names["ba"]['transcriber_name'].present? && names["ba"]['credit_name'].present?
        names["ba"]['transcriber_name'].each do |name|
          names["ba"]['credit_name'].delete_if { |x| x == name}
        end
      end
      names
    end

    def valid_freereg1_csv_file?(freereg1_csv_file)
      result = false
      return result if freereg1_csv_file.blank?

      freereg1_csv_file_object = Freereg1CsvFile.find(freereg1_csv_file)
      result = true if freereg1_csv_file_object.present? && Register.valid_register?(freereg1_csv_file_object.register_id)
      logger.warn("FREEREG:LOCATION:VALIDATION invalid freereg1_csv_file id #{freereg1_csv_file} ") unless result
      result
    end

    def freereg1_csv_file_valid?(freereg1_csv_file)
      if freereg1_csv_file.blank?
        logger.warn("#{App.name.upcase}:FREEREG_FILE_ERROR: entry had no file")
        result = false
      elsif Freereg1CsvFile.find_by(id: freereg1_csv_file).present?
        result = true
      else
        result = false
        logger.warn("#{App.name.upcase}:FREEREG_FILE_ERROR: #{freereg1_csv_file} not located")
      end
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

  def add_to_rake_delete_list
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
    self.save_to_attic
    file_folder = File.join(Rails.application.config.datafiles,self.userid)
    file_location = File.join(Rails.application.config.datafiles,self.userid,self.file_name)
    success = false
    if File.exists?(file_folder)
      self.write_csv_file(file_location)
      success = true
    end
    success
  end

  def calculate_distribution
    entries = freereg1_csv_entries
    datemin, zero_entries = Freereg1CsvFile.calculate_min_year(entries)
    datemax = Freereg1CsvFile.calculate_max_year(entries)
    number_of_records, daterange = Freereg1CsvFile.calculate_range_distribution(entries)
    update(datemin: datemin, datemax: datemax, daterange: daterange, records: number_of_records, zero_entries: zero_entries)
    success = true
    success = false if errors.any?
    success
  end

  def can_we_edit?
    result = PhysicalFile.userid(userid).file_name(file_name).waiting.blank? ? true : false
  end

  def change_owner_of_file(new_userid)
    # rspec tested
    # first step is to move the files
    old_userid = self.userid
    file_name = self.file_name
    result = [true,""]
    new_userid_folder_location = physical_userid_location(new_userid)
    old_userid_folder_location = physical_userid_location(old_userid)
    if Dir.exist?(old_userid_folder_location)
      unless Dir.exist?(new_userid_folder_location)
        Dir.mkdir(new_userid_folder_location,0774)
      end
      self.save_to_attic
      new_physical_file_location = physical_file_location(new_userid,file_name)
      old_physical_file_location = physical_file_location(old_userid,file_name)
      self.write_csv_file(new_physical_file_location)
      FileUtils.remove(old_physical_file_location, :force => true,:verbose => true) if File.exist?(old_physical_file_location)
    else
      result = [false, "Old userid does not exist"]
    end
    if result[0]
      physical_file = PhysicalFile.userid(old_userid).file_name(self.file_name).first
      if physical_file.present?
        physical_file.update_userid(new_userid)
      end
      self.promulgate_userid_change(new_userid,old_userid)
    end
    result
  end

  def check_and_augment_def(param)
    return unless self.def
    param.each_pair do |mykey, myvalue|
      if myvalue.present? && !(mykey == "multiple_witnesses_attributes") && !self.order.has_key?(mykey)
        end_member = self.order.max_by{ |k, v| v }[1]
        self.order[mykey] = end_member + 1
      end
      if mykey == "multiple_witnesses_attributes"
        def_witnesses = self.determine_number_of_def_witnesses
        edit_witnesses = param[mykey].values.length
        param[mykey].each_pair do |key, witval|
          edit_witnesses = edit_witnesses - 1 if (witval['id'].nil? && witval["witness_forename"].blank? && witval["witness_surname"].blank?)
        end
        if edit_witnesses < FreeregOptionsConstants::MAXIMUM_WINESSES
          while edit_witnesses > def_witnesses
            witness_forename = 'witness' + edit_witnesses.to_s + '_forename'
            witness_surname = 'witness' + edit_witnesses.to_s + '_surname'
            end_member = self.order.max_by{ |k, v| v }[1]
            self.order[witness_forename] = end_member + 1
            self.order[witness_surname] = end_member + 2
            def_witnesses = def_witnesses + 1
          end
        end
      end
    end
  end

  def check_batch
    success = Array.new
    success[0] = true
    success[1] = ""
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
    when freereg1_csv_entries.count == 0
      success[0] = false
      success[1] = success[1] + "batch has no entries #{batch} "
    when register.blank?
      success[0] = false
      success[1] = success[1] + "batch has a null register #{batch} "
    when register.church.blank?
      success[0] = false
      success[1] = success[1] + "batch has a null church #{batch} "
    when register.church.place.blank?
      success[0] = false
      success[1] = success[1] + "batch has a null church #{batch} "
    end
    success
  end

  def check_file
    success = Array.new
    success[0] = true
    success[1] = ""
    Freereg1CsvFile.file_name(self.file_name).userid(self.userid).each do |batch|
      case
      when batch.nil?
        success[0] = false
        success[1] = success[1] + "file #{batch.file_name} does not exist"
      when batch.file_name.blank?
        success[0] = false
        success[1] = success[1] + "file name is missing #{batch.file_name} "
      when batch.userid.blank?
        success[0] = false
        success[1] = success[1] + "userid is missing #{batch.file_name} "
      when batch.record_type.blank?
        success[0] = false
        success[1] = success[1] + "record type is missing #{batch.file_name} "
      when batch.freereg1_csv_entries.count == 0
        success[0] = false
        success[1] = success[1] + "file has no entries #{batch.file_name} "
      when batch.register.blank?
        success[0] = false
        success[1] = success[1] + "file has a null register #{batch.file_name} "
      when batch.register.church.blank?
        success[0] = false
        success[1] = success[1] + "file has a null church #{batch.file_name} "
      when batch.register.church.place.blank?
        success[0] =  false
        success[1] = success[1] + "file has a null church #{batch.file_name} "
      when batch.error > 0
        success[0] =  false
        success[1] = success[1] + "file has error records that would be lost for #{batch.file_name} "
      end
    end
    success
  end

  def check_locking_and_set(param,sess)
    if sess[:my_own]
      self.update_attributes(:locked_by_transcriber => true)
    else
      self.update_attributes(:locked_by_coordinator => true)
    end
  end

  def check_register_type
    errors.add(:register_type, "Invalid register type") unless RegisterType::OPTIONS.values.include?(self.register_type)
  end

  def clean_up
    update_statistics
    clean_up_place_ucf_list
  end

  def update_statistics
    update_number_of_files
    register = self.register
    if register.nil?
      logger.warn("FREEREG:#{self.id} does not belong to a register ")
      return
    else
      church = register.church
      if church.nil?
        logger.warn("FREEREG:#{register.id} does not belong to a church ")
        return
      else
        place = church.place
        if place.nil?
          logger.warn("FREEREG:#{church.id} does not belong to a place ")
          return
        else
          place.recalculate_last_amended_date
        end
      end
    end
  end

  def clean_up_place_ucf_list
    proceed, place, _church, _register = self.location_from_file
    if proceed && place.present?
      ucf_list = place.ucf_list
      ucf_list = ucf_list.delete_if {|key, value| key.to_s == self.id.to_s}
      place.update(ucf_list: ucf_list)
    end
  end

  def define_colour
    # need to consider storing the processed rather than a look up
    case
    when self.error != 0 && !self.locked_by_coordinator  && !self.locked_by_transcriber
      color = "color:red"
    when !self.processed
      color = "color:orange"
    when self.error == 0 && !self.locked_by_coordinator && !self.locked_by_transcriber
      color ="color:green"
    when self.error == 0 && (self.locked_by_coordinator || self.locked_by_transcriber )
      color = "color:blue"
    when self.error != 0 && (self.locked_by_coordinator || self.locked_by_transcriber)
      color = "color:maroon"
    else
      color = "color:black"
    end
    color
  end

  def determine_line_information(error_id)
    error_file = batch_errors.find(error_id)
    file_line_number = error_file.record_number if error_file.present?
    line_id = error_file.data_line[:line_id]
    [file_line_number, line_id]
  end

  def all_embargoed_entries
    freereg1_csv_entries = []
    self.freereg1_csv_entries.each do |entry|
      freereg1_csv_entries << entry if entry.embargo_records.present?
    end
    freereg1_csv_entries
  end

  def force_unlock
    batches = Freereg1CsvFile.where(:file_name => self.file_name, :userid => self.userid).all
    batches.each do |batch|
      batch.update_attributes(:locked_by_coordinator => false)
      batch.update_attributes(:locked_by_transcriber => false)
    end
  end

  def get_zero_year_entries
    freereg1_csv_entries = []
    self.freereg1_csv_entries.each do |entry|
      freereg1_csv_entries << entry if entry.year.nil? || entry.year == '0'
    end
    freereg1_csv_entries
  end

  def location_from_file
    my_register = register
    return [false] unless Register.register_valid?(my_register)

    my_church = my_register.church
    return [false] unless Church.church_valid?(my_church)

    my_place = my_church.place
    return [false] unless Place.place_valid?(my_place)

    [true, my_place, my_church, my_register]
  end

  def lock(type)
    batches = Freereg1CsvFile.where(:file_name => self.file_name, :userid => self.userid).all
    set_transciber_lock = !self.locked_by_transcriber
    set_coordinator_lock = !self.locked_by_coordinator
    batches.each do |batch|
      if type
        # transcriber is changing their lock
        batch.update_attributes(:locked_by_transcriber => set_transciber_lock)
      else
        # coordinator is changing locks
        batch.update_attributes(:locked_by_coordinator => set_coordinator_lock)
        batch.update_attributes(:locked_by_transcriber => false) unless set_coordinator_lock
      end
    end
  end

  def lock_all(type)
    batches = Freereg1CsvFile.where(:file_name => self.file_name, :userid => self.userid).all
    batches.each do |batch|
      if type
        # transcriber is changing their lock
        batch.update_attributes(:locked_by_transcriber => true)
      else
        # coordinator is changing locks
        batch.update_attributes(:locked_by_coordinator => true)
      end
    end
  end

  def marriage_record(place,church_name,rec,witness1,witness2,note,file)
    csv_hold = ["#{place.chapman_code}","#{place.place_name}","#{church_name}",
                "#{rec.register_entry_number}","#{rec.marriage_date}","#{rec.groom_forename}","#{rec.groom_surname}","#{rec.groom_age}","#{rec.groom_parish}",
                "#{rec.groom_condition}","#{rec.groom_occupation}","#{rec.groom_abode}","#{rec.bride_forename}","#{rec.bride_surname}","#{rec.bride_age}",
                "#{rec.bride_parish}","#{rec.bride_condition}","#{rec.bride_occupation}","#{rec.bride_abode}","#{rec.groom_father_forename}","#{rec.groom_father_surname}",
                "#{rec.groom_father_occupation}","#{rec.bride_father_forename}","#{rec.bride_father_surname}","#{rec.bride_father_occupation}",
                "#{witness1[0]}","#{witness1[1]}","#{witness2[0]}","#{witness2[1]}","#{rec.notes}#{note}"]
    csv_hold = csv_hold + ["#{rec.film}", "#{rec.film_number}"] if file.lds =='yes'
    csv_hold
  end

  def merge_batches
    batch_id = self._id
    register = self.register
    self.force_unlock
    added_records = 0
    register.freereg1_csv_files.each do |batch|
      if batch.userid == self.userid && batch.file_name == self.file_name
        unless batch._id == batch_id
          batch.freereg1_csv_entries.each do |entry|
            added_records = added_records + 1
            entry.update_attribute(:freereg1_csv_file_id, batch_id)
          end
          register.freereg1_csv_files.delete(batch)
          batch.delete
        end
      end
    end
    # TODO need to recompute max, min and range
    unless added_records == 0
      logger.info "FREEREG:update record count #{self.records.to_i} and #{added_records}"
      records = self.records.to_i + added_records
      self.update_attributes(:records => records.to_s,:locked_by_coordinator => true )
      logger.info "FREEREG:updated record count #{self.records.to_i} "
    end
    [true, ""]
  end

  def physical_userid_location(userid)
    location = File.join(Rails.application.config.datafiles,userid)
  end

  def physical_file_location(userid,file_name)
    location = File.join(Rails.application.config.datafiles,userid,file_name)
  end

  def old_place
    reg_id = self.register_id
    church_id = Register.find(reg_id).church_id
    old_place_id = Church.find(church_id).place_id
  end

  def promulgate_userid_change(new_userid,old_userid)
    # since a file may have many batches we must change them all as we have moved the file
    new_userid_detail = UseridDetail.userid(new_userid).first
    Freereg1CsvFile.userid(old_userid).file_name(self.file_name).each do |batch|
      success = Freereg1CsvEntry.update_entries_userid(new_userid,batch)
      batch.update_attributes(:userid => new_userid, :userid_lower_case => new_userid.downcase, :userid_detail_id =>new_userid_detail.id) if success
    end
  end

  def propogate_file_location_change(place_id)
    location_names = []
    place_name = self.place
    church_name = self.church_name
    register_type = RegisterType.display_name(self.register_type)
    location_names << "#{place_name} (#{church_name})"
    location_names  << " [#{register_type}]"
    self.freereg1_csv_entries.no_timeout.each do |entry|
      if entry.search_record.nil?
        logger.info "FREEREG:search record missing for entry #{entry._id}"
      else
        entry.update_attributes(:place => place_name, :church_name => church_name)
        record = entry.search_record
        record.location_names = location_names
        record.chapman_code = self.county
        record.place_id = place_id
        record.save
      end
    end
  end

  def recalculate_last_amended
    register = self.register
    return if register.blank?
    church = register.church
    return if church.blank?
    place = church.place
    return if place.blank?
    place.recalculate_last_amended_date
  end

  def save_to_attic
    # rspected with removal
    #Rails.logger.debug "Saving to attic"
    # to-do unix permissions
    file = self.file_name
    file_location = File.join(Rails.application.config.datafiles,self.userid,file)
    if File.file?(file_location)
      newdir = File.join(File.join(Rails.application.config.datafiles,self.userid),'.attic')
      Dir.mkdir(newdir) unless Dir.exists?(newdir)
      time = Time.now.to_i.to_s
      renamed_file = (file_location + "." + time).to_s
      File.rename(file_location,renamed_file)
      FileUtils.mv(renamed_file,newdir,:verbose => true)
      user =UseridDetail.where(:userid => self.userid).first
      unless user.nil?
        attic_file = AtticFile.new(:name => "#{file}.#{time}", :date_created => DateTime.strptime(time,'%s'), :userid_detail_id => user.id)
        attic_file.save
      end
    else
      Rails.logger.debug "Nothing to save to attic"
    end
  end

  def remove_batch
    case
    when self.records.to_i > 5000
      UserMailer.report_to_data_manger_of_large_file( self.file_name,self.userid).deliver_now
      return false,'There are too many records for a simple removal. Please discuss with your coordinator or the data managers how best to deal with its restructuring'
    when self.locked_by_transcriber || self.locked_by_coordinator
      return false,'The removal of the batch was unsuccessful; the batch is locked'
    else
      # deal with file and its records
      add_to_rake_delete_list
      save_to_attic
      clean_up_place_ucf_list
      delete
      # deal with the Physical Files collection
      PhysicalFile.delete_document(self.userid, self.file_name)
      [true, 'The removal of the batch entry was successful']
    end
  end

  def remove_from_ucf_list
    proceed, place, _church, _register = location_from_file
    if proceed
      place.ucf_list.delete_if { |key, value| key.to_s == id.to_s }
      place.save
    end
  end

  def search_record_ids_with_wildcard_ucf
    ids = []
    self.freereg1_csv_entries.each do |entry|
      entry.reload
      ids << entry.search_record.id if entry.search_record && entry.search_record.contains_wildcard_ucf?
    end
    ids
  end

  def to_register
    { :chapman_code => county,
      :register_type => register_type,
      :place_name => place,
      :church_name => church_name,
      :alternate_register_name => alternate_register_name,
      :last_amended => modification_date,
      :transcription_date => transcription_date,
      :record_types => [record_type]
      }
  end
  def update_freereg_contents_after_processing
    register = self.register
    register.calculate_register_numbers
    church = register.church
    church.calculate_church_numbers
    place = church.place
    place.calculate_place_numbers
  end

  def update_statistics_and_access(who_actioned)
    Rails.logger.debug 'update_statistics_and_access'
    self.locked_by_transcriber = true if who_actioned
    self.locked_by_coordinator = true unless who_actioned
    self.modification_date = Time.now.strftime("%d %b %Y")
    calculate_distribution
    recalculate_last_amended
    update_number_of_files
    save
    proceed, place, church, register = location_from_file
    if proceed
      register.calculate_register_numbers
      church.calculate_church_numbers
      place.calculate_place_numbers
    end
  end

  def update_number_of_files
    # this code although here and works produces values in fields that are no longer being used
    userid = UseridDetail.where(:userid => self.userid).first
    return if userid.nil?
    files = userid.freereg1_csv_files
    if files.length.nil?
      number = 0
      records = 0
      last_uploaded = DateTime.new(1998,1,1)
    else
      number = files.length
      last_uploaded = DateTime.new(1998,1,1)
      records = 0
      files.each do |file|
        records = records + file.records.to_i
        last_uploaded = file.uploaded_date if last_uploaded.nil? || file.uploaded_date >= last_uploaded
      end
      userid.update_attributes(:number_of_files  => number, :number_of_records => records, :last_upload => last_uploaded)
    end
  end

  def update_register
    Register.update_or_create_register(self)
  end

  def calculate_transcriber_name(key)
    if record_type == key && userid_detail.present? && (userid_detail.person_surname.present? || userid_detail.person_forename.present?)
      answer, transcriber =  UseridDetail.can_we_acknowledge_the_transcriber(userid_detail)
      transcriber = nil unless answer
    end
    transcriber
  end

  def write_csv_file(file_location)
    file = self
    # since there can be multiple places/churches in a single file we must combine the records for all those back into the single file
    chapman_code, place_name, church_name, register_type, proceed = file.write_csv_get_location
    fields = file.field_order_of_csv
    CSV.open(file_location, "wb", { :row_sep => "\r\n"}) do |csv|
      file.write_csv_headers(csv,fields)
      # eg +INFO,David@davejo.eclipse.co.uk,password,SEQUENCED,BURIALS,cp850,,,,,,,
      records = file.freereg1_csv_entries
      records.each do |rec|
        case
        when file.record_type == "ba"
          file.write_csv_baptism(csv,rec,fields,chapman_code, place_name, church_name, register_type)
        when file.record_type == "bu"
          file.write_csv_burial(csv,rec,fields,chapman_code, place_name, church_name, register_type)
        when file.record_type == "ma"
          file.write_csv_marriage(csv,rec,fields,chapman_code, place_name, church_name, register_type)
        end #end case
      end #end records
    end #end csv
  end #end method

  def write_csv_baptism(csv,rec,fields,chapman_code, place_name, church_name, register_type)
    record = Array.new
    fields.each do |field|
      case field
      when :chapman_code
        record = record.push(chapman_code.to_s)
      when :place_name
        record = record.push(place_name.to_s)
      when :church_name
        record = record.push(church_name.to_s)
      else
        record = record.push(rec[field.to_sym].to_s)
      end
    end
    csv << record
  end

  def write_csv_burial(csv,rec,fields,chapman_code, place_name, church_name, register_type)
    record = Array.new
    fields.each do |field|
      case field
      when :chapman_code
        record = record.push(chapman_code.to_s)
      when :place_name
        record = record.push(place_name.to_s)
      when :church_name
        record = record.push(church_name.to_s)
      else
        record = record.push(rec[field.to_sym].to_s)
      end
    end
    csv << record
  end

  def write_csv_marriage(csv,rec,fields,chapman_code, place_name, church_name, register_type)
    number_of_witnesses = rec.multiple_witnesses.count
    case
    when !self.def
      self.write_csv_marriage_standard(csv,rec,fields,chapman_code, place_name, church_name, register_type)
    when self.def &&  number_of_witnesses <= 2
      self.write_csv_marriage_standard(csv,rec,fields,chapman_code, place_name, church_name, register_type)
    when self.def && (number_of_witnesses >2 && number_of_witnesses <= 10)
      self.write_csv_marriage_flexible(csv,rec,fields,chapman_code, place_name, church_name, register_type)
    end
  end

  def write_csv_marriage_standard(csv,rec,fields,chapman_code, place_name, church_name, register_type)
    witnesses = rec.get_listing_of_witnesses
    number_of_witnesses = witnesses.length
    if number_of_witnesses == 0
      self.write_csv_marriage_standard_line(csv,rec,fields,chapman_code, place_name, church_name, register_type,witnesses)
    else
      while number_of_witnesses > 0
        self.write_csv_marriage_standard_line(csv,rec,fields,chapman_code, place_name, church_name, register_type,witnesses)
        number_of_witnesses = number_of_witnesses - 2
        witnesses = witnesses.drop(2)
      end
    end
  end

  def write_csv_marriage_standard_line(csv,rec,fields,chapman_code, place_name, church_name, register_type,witnesses)
    witnesses.length > 2 ? dup_notice = true : dup_notice = false
    record = Array.new
    fields.each do |field|
      case field
      when :chapman_code
        record = record.push(chapman_code.to_s)
      when :place_name
        record = record.push(place_name.to_s)
      when :church_name
        record = record.push(church_name.to_s)
      when :witness1_forename
        witnesses.blank? || witnesses[0].nil? ? record = record.push('') : record = record.push(witnesses[0][0].to_s)
      when :witness1_surname
        witnesses.blank? || witnesses[0].nil? ? record = record.push('') : record = record.push(witnesses[0][1].to_s)
      when :witness2_forename
        witnesses.blank? || witnesses[1].nil? ? record = record.push('') : record = record.push(witnesses[1][0].to_s)
      when :witness2_surname
        witnesses.blank? || witnesses[1].nil? ? record = record.push('') : record = record.push(witnesses[1][1].to_s)
      when :notes
        dup_notice ? notes = rec[field.to_sym].to_s + ' duplicated record for other witnesses' : notes = rec[field.to_sym].to_s
        record = record.push(notes)
      else
        record = record.push(rec[field.to_sym].to_s)
      end
    end
    csv << record
  end

  def write_csv_marriage_flexible(csv,rec,fields,chapman_code, place_name, church_name, register_type)
    witnesses = rec.get_listing_of_witnesses
    record = Array.new
    fields.each do |field|
      case field
      when :chapman_code
        record = record.push(chapman_code.to_s)
      when :place_name
        record = record.push(place_name.to_s)
      when :church_name
        record = record.push(church_name.to_s)
      when :witness1_forename
        witnesses.blank? || witnesses[0].nil? ? record = record.push('') : record = record.push(witnesses[0][0].to_s)
      when :witness1_surname
        witnesses.blank? || witnesses[0].nil? ? record = record.push('') : record = record.push(witnesses[0][1].to_s)
      when :witness2_forename
        witnesses.blank? || witnesses[1].nil? ? record = record.push('') : record = record.push(witnesses[1][0].to_s)
      when :witness2_surname
        witnesses.blank? || witnesses[1].nil? ? record = record.push('') : record = record.push(witnesses[1][1].to_s)
      when :witness3_forename
        witnesses.blank? || witnesses[2].nil? ? record = record.push('') : record = record.push(witnesses[2][0].to_s)
      when :witness3_forename_surname
        witnesses.blank? || witnesses[2].nil? ? record = record.push('') : record = record.push(witnesses[2][1].to_s)
      when :witness4_forename
        witnesses.blank? || witnesses[3].nil? ? record = record.push('') : record = record.push(witnesses[3][0].to_s)
      when :witness4_surname
        witnesses.blank? || witnesses[3].nil? ? record = record.push('') : record = record.push(witnesses[3][1].to_s)
      when :witness5_forename
        witnesses.blank? || witnesses[4].nil? ? record = record.push('') : record = record.push(witnesses[4][0].to_s)
      when :witness5_surname
        witnesses.blank? || witnesses[4].nil? ? record = record.push('') : record = record.push(witnesses[4][1].to_s)
      when :witness6_forename
        witnesses.blank? || witnesses[5].nil? ? record = record.push('') : record = record.push(witnesses[5][0].to_s)
      when :witness6_surname
        witnesses.blank? || witnesses[5].nil? ? record = record.push('') : record = record.push(witnesses[5][1].to_s)
      when :witness7_forename
        witnesses.blank? || witnesses[6].nil? ? record = record.push('') : record = record.push(witnesses[6][0].to_s)
      when :witness7_surname
        witnesses.blank? || witnesses[6].nil? ? record = record.push('') : record = record.push(witnesses[6][1].to_s)
      when :witness8_forename
        witnesses.blank? || witnesses[7].nil? ? record = record.push('') : record = record.push(witnesses[7][0].to_s)
      when :witness8_surname
        witnesses.blank? || witnesses[7].nil? ? record = record.push('') : record = record.push(witnesses[7][1].to_s)
      when :witness9_forename
        witnesses.blank? || witnesses[8].nil? ? record = record.push('') : record = record.push(witnesses[8][0].to_s)
      when :witness9_surname
        witnesses.blank? || witnesses[8].nil? ? record = record.push('') : record = record.push(witnesses[8][1].to_s)
      when :witness10_forename
        witnesses.blank? || witnesses[9].nil? ? record = record.push('') : record = record.push(witnesses[9][0].to_s)
      when :witness10_surname
        witnesses.blank? || witnesses[9].nil? ? record = record.push('') : record = record.push(witnesses[9][1].to_s)
      when :witness8_forename
      when :notes
        notes = rec[field.to_sym].to_s
        record = record.push(notes)
      else
        record = record.push(rec[field.to_sym].to_s)
      end
    end
    csv << record
  end

  def write_csv_headers(csv,fields)
    file = self
    record_type = RecordType.display_name(file.record_type).upcase + 'S' unless file.record_type.blank?
    csv << ["+INFO","#{file.transcriber_email}","PASSWORD","SEQUENCED","#{record_type}","#{file.characterset}"]
    # eg #,CCCC,David Newbury,Derbyshire,dbysmalbur.CSV,02-Mar-05,,,,,,,
    csv << ['#','CCC',file.transcriber_name,file.transcriber_syndicate,file.file_name,file.transcription_date]
    # eg #,Credit,Libby,email address,,,,,,
    csv << ['#','CREDIT',file.credit_name,file.credit_email]
    # eg #,05-Feb-2006,data taken from computer records and converted using Excel, LDS
    csv << ['#',Time.now.strftime("%d-%b-%Y"),file.first_comment,file.second_comment]
    #eg +LDS,,,,
    csv << ['+LDS'] unless file.def
    if file.def
      csv << ['#','DEF']
      csv << fields
    end
  end

  def field_order_of_csv
    if self.order.present?
      hash_of_fields = self.order
    else
      hash_of_fields =  FreeregOptionsConstants::ENTRY_ORDER_DEFINITION[self.record_type]
    end
    hash_of_fields = hash_of_fields.symbolize_keys
    fields = Array.new
    hash_of_fields.values.sort.each do |val|
      fields << hash_of_fields.key(val)
    end
    fields.delete(:county)
    fields.delete(:place)
    fields.delete(:record_type)
    return fields
  end

  def write_csv_get_location
    register = self.register
    church = register.church
    place = church.place
    proceed = true
    chapman_code = place.chapman_code
    place_name = place.place_name
    church_name = church.church_name
    register_type = register.register_type
    church_name = church_name.to_s + " " + register_type.to_s if !self.def || (self.order.present? && !self.order.stringify_keys.has_key?('register_type'))
    proceed = false if (chapman_code.blank? || place_name.blank? || church_name.blank?)
    return chapman_code, place_name, church_name, register_type, proceed
  end

  def get_unique_names
    entries = Hash.new
    all_entries = Freereg1CsvEntry.where(:freereg1_csv_file_id => self.id)
    case self.record_type
    when "ba"
      entries["Father's Surname"] = all_entries.distinct(:father_surname).delete_if{|x| x == nil}.sort
      entries["Mother's Surname"] = all_entries.distinct(:mother_surname).delete_if{|x| x == nil}.sort
      entries["Father's Forename"] = all_entries.distinct(:father_forename).delete_if{|x| x == nil}.sort
      entries["Mother's Forename"] = all_entries.distinct(:mother_forename).delete_if{|x| x == nil}.sort
      entries["Person's Forename"] = all_entries.distinct(:person_forename).delete_if{|x| x == nil}.sort
      entries["Person's Surname"] = all_entries.distinct(:person_surname).delete_if{|x| x == nil}.sort
      entries["Witness Surname"] = all_entries.distinct('multiple_witnesses.witness_surname').delete_if{|x| x == nil}.sort
      entries["Witness Forename"] = all_entries.distinct('multiple_witnesses.witness_forename').delete_if{|x| x == nil}.sort
    when "bu"
      entries["Burial Person's Surname"] = all_entries.distinct(:burial_person_surname).delete_if{|x| x == nil}.sort
      entries["Burial Person's Forename"] = all_entries.distinct(:burial_person_forename).delete_if{|x| x == nil}.sort
      entries["Relative's Surname"] = all_entries.distinct(:relative_surname).delete_if{|x| x == nil}.sort
      entries["Male Relative's Forename"] = all_entries.distinct(:male_relative_forename).delete_if{|x| x == nil}.sort
      entries["Female Relative's Forename"] = all_entries.distinct(:female_relative_forename).delete_if{|x| x == nil}.sort
      entries["Female Relative's Surname"] = all_entries.distinct(:female_relative_surname).delete_if{|x| x == nil}.sort
    when "ma"
      entries["Groom's Surname"] = all_entries.distinct(:groom_surname).delete_if{|x| x == nil}.sort
      entries["Groom's Forename"] = all_entries.distinct(:groom_forename).delete_if{|x| x == nil}.sort
      entries["Bride's Surname"] = all_entries.distinct(:bride_surname).delete_if{|x| x == nil}.sort
      entries["Bride's Forename"] = all_entries.distinct(:bride_forename).delete_if{|x| x == nil}.sort
      entries["Groom's Father's Surname"] = all_entries.distinct(:groom_father_surname).delete_if{|x| x == nil}.sort
      entries["Groom's Father's Forename"] = all_entries.distinct(:groom_father_forename).delete_if{|x| x == nil}.sort
      entries["Bride's Father's Surname"] = all_entries.distinct(:bride_father_surname).delete_if{|x| x == nil}.sort
      entries["Bride's Father's Forename"] = all_entries.distinct(:bride_father_forename).delete_if{|x| x == nil}.sort
      entries["Groom's Mother's Surname"] = all_entries.distinct(:groom_mother_surname).delete_if{|x| x == nil}.sort
      entries["Groom's Mother's Forename"] = all_entries.distinct(:groom_mother_forename).delete_if{|x| x == nil}.sort
      entries["Bride's Mother's Surname"] = all_entries.distinct(:bride_motherr_surname).delete_if{|x| x == nil}.sort
      entries["Bride's Mother's Forename"] = all_entries.distinct(:bride_mother_forename).delete_if{|x| x == nil}.sort
      entries["Witness Surname"] = all_entries.distinct('multiple_witnesses.witness_surname').delete_if{|x| x == nil}.sort
      entries["Witness Forename"] = all_entries.distinct('multiple_witnesses.witness_forename').delete_if{|x| x == nil}.sort
    end
    entries
  end

  def zero_year_entries
    freereg1_csv_entries = Array.new
    Freereg1CsvEntry.freereg1_csv_file(id).year(nil).each do |entry|
      freereg1_csv_entries << entry
    end
    freereg1_csv_entries
  end

  def date_change(transcription_date, modification_date)
    error = self.error
    if error > 0
      lines = self.batch_errors.all
      lines.each do |line|
        if line.error_type == 'Header_Error'
          if /^Header_Error,The transcription date/ =~ line.error_message
            unless self.transcription_date == transcription_date
              line.destroy
              error = error - 1
              self.update_attributes(:error => error)
            end
          end
          if /^Header_Error,The modification date/ =~ line.error_message
            unless self.modification_date == modification_date
              line.destroy
              error = error - 1
              self.update_attributes(:error => error)
            end
          end
        end
      end
    end
  end

  def determine_number_of_def_witnesses
    fields = order
    witnesses = 0
    fields.each_key do |key|
      if key.include?("witness") && (key.include?("_forename") || key.include?("_surname"))
        witnesses = witnesses + 1
      end
    end
    witnesses = witnesses / 2.0
    witnesses.to_i
  end
end
