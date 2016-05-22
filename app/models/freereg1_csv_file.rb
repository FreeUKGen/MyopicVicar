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
  require 'csv'

  # Fields correspond to cells in CSV headers
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  #These field are there in the entry collection from the original files coming in as CSV file.
  #They are NOT USED we use the county and country from the Place collection the church_name from the church collection
  #and the register information from the register collection
  field :country, type: String
  field :county, type: String #note in headers this is actually a Chapman code
  field :chapman_code,  type: String
  field :church_name, type: String
  field :register_type, type: String
  field :record_type, type: String#, :in => RecordType::ALL_TYPES+[nil]
  validates_inclusion_of :record_type, :in => RecordType::ALL_FREEREG_TYPES+[nil]
  #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  field :place, type: String
  field :place_name, type: String
  field :records, type: String
  field :datemin, type: String
  field :datemax, type: String
  field :daterange, type: Array
  field :userid, type: String
  field :userid_lower_case, type: String
  field :file_name, type: String
  field :transcriber_name, type: String
  field :transcriber_email, type: String
  field :transcriber_syndicate, type: String
  field :credit_email, type: String
  field :credit_name, type: String
  field :first_comment, type: String
  field :second_comment, type: String
  field :transcription_date, type: String, default: -> {"01 Jan 1998"}
  field :modification_date, type: String, default: -> {"01 Jan 1998"}
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
  field :software_version, type: String
  field :search_record_version, type: String

  index({file_name:1,userid:1,county:1,place:1,church_name:1,register_type:1})
  index({county:1,place:1,church_name:1,register_type:1, record_type: 1})
  index({file_name:1,error:1})
  index({error:1, file_name:1})

  before_save :add_lower_case_userid
  after_save :recalculate_last_amended, :update_number_of_files

  before_destroy do |file|
    file.save_to_attic
    entries = Freereg1CsvEntry.where(:freereg1_csv_file_id => file._id).all.no_timeout
    num = Freereg1CsvEntry.where(:freereg1_csv_file_id => file._id).count
    entries.each do |entry|
      entry.destroy
      #sleep_time = 2*(Rails.application.config.sleep.to_f)
      #sleep(sleep_time)
    end
  end

  after_destroy :clean_up

  has_many :freereg1_csv_entries, validate: false
  belongs_to :register, index: true
  belongs_to :userid_detail, index: true

  #register belongs to church which belongs to place

  has_many :batch_errors

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

  class << self
    def syndicate(name)
      where(:transcriber_syndicate => name)
    end
    def county(name)
      where(:county => name)
    end
    def place(name)
      where(:place => name)
    end
    def chapman_code(name)
      #note chapman is county in file
      where(:county => name)
    end
    def record_type(name)
      where(:record_type => name)
    end
    def userid(name)
      where(:userid => name)
    end
    def church_name(name)
      where(:church_name => name)
    end
    def register_type(name)
      where(:register_type => name)
    end
    def file_name(name)
      where(:file_name => name)
    end
    def id(id)
      where(:id => id)
    end
    def errors
      where(:error.gt => 0)
    end
    def transcriber_lock
      where(:locked_by_transcriber => true)
    end
    def coordinator_lock
      where(:locked_by_coordinator => true)
    end
  end

  def add_lower_case_userid
    self[:userid_lower_case] = self[:userid].downcase
  end


  def update_register
    Register.update_or_create_register(self)
  end

  def to_register
    { :chapman_code => county,
      :register_type => register_type,
      :place_name => place,
      :church_name => church_name,
      :alternate_register_name => alternate_register_name,
      :last_amended => modification_date,
      :transcription_date => transcription_date,
      :record_types => [record_type],

      }
  end



  def self.combine_files(all_files)
    number_of_files = all_files.length unless all_files.blank?
    holding_information = Hash.new
    holding_information["ba"] = Hash.new
    holding_information["bu"] = Hash.new
    holding_information["ma"] = Hash.new
    nm = 0
    nba = 0
    nbu = 0
    all_files.each do |individual_file|
      case
      when individual_file.record_type == "ba"
        combine_now_new(holding_information["ba"],individual_file,nba,number_of_files)
        nba = nba + 1
      when individual_file.record_type == "bu"
        combine_now_new(holding_information["bu"],individual_file,nbu,number_of_files)
        nbu = nbu + 1
      when individual_file.record_type == "ma"
        combine_now_new(holding_information["ma"],individual_file,nm,number_of_files)
        nm = nm + 1
      end
    end
    holding_information = Freereg1CsvFile.unique_names(holding_information)
    holding_information
  end
  def self.combine_now_new(holding,individual,index,number)
    if index == 0
      holding['transcriber_name'] = Array.new
      holding['credit_name'] = Array.new
      holding['records'] = individual.records
      holding['datemax'] = individual.datemax
      holding['datemin'] = individual.datemin
      holding['daterange'] = individual.daterange
      holding['transcriber_name'] << individual.transcriber_name.strip.gsub(/\s+/, ' ').downcase.split.map(&:capitalize).join(' ') unless individual.transcriber_name.blank?
      holding['credit_name'] << individual.credit_name.strip.gsub(/\s+/, ' ').downcase.split.map(&:capitalize).join(' ') unless individual.credit_name.blank?
      holding['transcription_date'] = individual.transcription_date
      holding['modification_date'] = individual.modification_date
    end
    if index > 0 && index <= number
      holding['records'] = holding['records'].to_i + individual.records.to_i
      holding['datemax'] = individual.datemax.to_i  if individual.datemax.to_i > holding['datemax'].to_i
      holding['datemin'] = individual.datemin.to_i if individual.datemin.to_i < holding['datemin'].to_i
      holding['daterange'].each_index do |i|
        holding['daterange'][i] = holding['daterange'][i].to_i + individual.daterange[i].to_i
      end
      holding['transcriber_name'] << individual.transcriber_name.strip.gsub(/\s+/, ' ').downcase.split.map(&:capitalize).join(' ') unless individual.transcriber_name.blank?
      holding['credit_name'] << individual.credit_name.strip.gsub(/\s+/, ' ').downcase.split.map(&:capitalize).join(' ') unless individual.credit_name.blank?
      holding['transcription_date'] = individual.transcription_date if (Freereg1CsvFile.convert_date(individual.transcription_date) < Freereg1CsvFile.convert_date(holding['transcription_date']))
      holding['modification_date'] = individual.modification_date if (Freereg1CsvFile.convert_date(individual.modification_date) > Freereg1CsvFile.convert_date(holding['modification_date']))
    end
  end


  def self.delete_file(file)
    file.save_to_attic
    p "Deleting file and entries"
    Freereg1CsvFile.where(:userid  => file.userid, :file_name => file.file_name).all.each do |f|
      entries = Freereg1CsvEntry.where(:freereg1_csv_file_id => file._id).all.no_timeout
      p "#{entries.length}" unless entries.nil?
      entries.destroy_all
      f.delete unless f.nil?
    end
  end

  def save_to_attic
    p "Saving to attic"
    #to-do unix permissions
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
      p "Nothing to save to attic"
    end
  end

  def self.convert_date(date_field)
    #use a custom date covertion to number of days for comparison purposes only
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
      success[0] =  false
      success[1] = success[1] + "batch has a null church #{batch} "
    end
    success
  end

  def check_file
    success = Array.new
    success[0] = true
    success[1] = ""
    Freereg1CsvFile.file_name(self.file_name).userid(self.userid).hint("file_name_1_userid_1_county_1_place_1_church_name_1_register_type_1").each do |batch|
      case batch
      when nil?
        success[0] = false
        success[1] = success[1] + "file #{batch} does not exist"
      when file_name.blank?
        success[0] = false
        success[1] = success[1] + "file name is missing #{batch} "
      when userid.blank?
        success[0] = false
        success[1] = success[1] + "userid is missing #{batch} "
      when record_type.blank?
        success[0] = false
        success[1] = success[1] + "record type is missing #{batch} "
      when freereg1_csv_entries.count == 0
        success[0] = false
        success[1] = success[1] + "file has no entries #{batch} "
      when register.blank?
        success[0] = false
        success[1] = success[1] + "file has a null register #{batch} "
      when register.church.blank?
        success[0] = false
        success[1] = success[1] + "file has a null church #{batch} "
      when register.church.place.blank?
        success[0] =  false
        success[1] = success[1] + "file has a null church #{batch} "
      end
      return success if !success[0]
    end
    success
  end
  def backup_file
    #this makes aback up copy of the file in the attic and creates a new one
    self.save_to_attic
    file_location = File.join(Rails.application.config.datafiles,self.userid,self.file_name)
    self.write_csv_file(file_location)
  end

  def write_csv_file(file_location)
    file = self
    #since there can be multiple places/churches in a single file we must combine the records for all those back into the single file
    file_parts = Freereg1CsvFile.where(:file_name => file.file_name, :userid => file.userid).all
    CSV.open(file_location, "wb", { :row_sep => "\r\n"}) do |csv|
      # eg +INFO,David@davejo.eclipse.co.uk,password,SEQUENCED,BURIALS,cp850,,,,,,,
      record_type = RecordType.display_name(file.record_type).upcase + 'S' unless file.record_type.blank?
      csv << ["+INFO","#{file.transcriber_email}","PASSWORD","SEQUENCED","#{record_type}","#{file.characterset}"]
      # eg #,CCCC,David Newbury,Derbyshire,dbysmalbur.CSV,02-Mar-05,,,,,,,
      csv << ['#','CCC',file.transcriber_name,file.transcriber_syndicate,file.file_name,file.transcription_date]
      # eg #,Credit,Libby,email address,,,,,,
      csv << ['#','CREDIT',file.credit_name,file.credit_email]
      # eg #,05-Feb-2006,data taken from computer records and converted using Excel, LDS
      csv << ['#',Time.now.strftime("%d-%b-%Y"),file.first_comment,file.second_comment]
      #eg +LDS,,,,
      csv << ['+LDS'] if file.lds || file.lds =='yes'


      register = file.register
      church = register.church
      place = church.place
      records = file.freereg1_csv_entries
      records.each do |rec|
        church_name = church.church_name.to_s + " " + register.register_type.to_s
        case
        when file.record_type == "ba"

          csv_hold = ["#{place.chapman_code}","#{place.place_name}","#{church_name}",
                      "#{rec.register_entry_number}","#{rec.birth_date}","#{rec.baptism_date}","#{rec.person_forename}","#{rec.person_sex}",
                      "#{rec.father_forename}","#{rec.mother_forename}","#{rec.father_surname}","#{rec.mother_surname}","#{rec.person_abode}",
                      "#{rec.father_occupation}","#{rec.notes}"]
          csv_hold = csv_hold + ["#{rec.film}", "#{rec.film_number}"] if file.lds =='yes'
          csv << csv_hold

        when file.record_type == "bu"

          csv_hold = ["#{place.chapman_code}","#{place.place_name}","#{church_name}",
                      "#{rec.register_entry_number}","#{rec.burial_date}","#{rec.burial_person_forename}",
                      "#{rec.relationship}","#{rec.male_relative_forename}","#{rec.female_relative_forename}","#{rec.relative_surname}",
                      "#{rec.burial_person_surname}","#{rec.person_age}","#{rec.burial_person_abode}","#{rec.notes}"]
          csv_hold = csv_hold + ["#{rec.film}", "#{rec.film_number}"] if file.lds =='yes'
          csv << csv_hold

        when file.record_type == "ma"
          witnesses = rec.get_listing_of_witnesses
          witnesses.present? ? number_of_witnesses = witnesses.length : number_of_witnesses = 0
          witness1 = Array.new(2)
          witness2 = Array.new(2)
          case
          when number_of_witnesses == 0
            witness1[0] = witness1[1] = witness2[0] = witness2[1] = note = ''
            csv_hold = self.marriage_record(place,church_name,rec,witness1,witness2,note,file)
            csv << csv_hold
          when number_of_witnesses == 1
            witness2[0] = witness2[1] = note = ''
            witness1 = witnesses[0]
            csv_hold = self.marriage_record(place,church_name,rec,witness1,witness2,note,file)
            csv << csv_hold
          when number_of_witnesses == 2
            witness1 = witnesses[0]
            witness2 = witnesses[1]
            note = ''
            csv_hold = self.marriage_record(place,church_name,rec,witness1,witness2,note,file)
            csv << csv_hold
          when number_of_witnesses > 2
            while number_of_witnesses > 0
              case
              when number_of_witnesses.odd?
                witness2[0]  = ''
                witness2[1] = ''
                witness1 = witnesses[-1]
                note = "duplicated for additional witnesses"
                witnesses.pop(1) unless witnesses.blank?
                number_of_witnesses = number_of_witnesses - 1
                csv_hold = self.marriage_record(place,church_name,rec,witness1,witness2,note,file)
                csv << csv_hold
              when number_of_witnesses.even?
                witness1 = witnesses[-2]
                witness2 = witnesses[-1]
                note = "duplicated for additional witnesses"
                witnesses.pop(2) unless witnesses.blank?
                number_of_witnesses = number_of_witnesses - 2
                csv_hold = self.marriage_record(place,church_name,rec,witness1,witness2,note,file)
                csv << csv_hold
              end
            end
          end
        end #end case
      end #end records
    end #end csv
  end #end method

  def marriage_record(place,church_name,rec,witness1,witness2,note,file)
    csv_hold = ["#{place.chapman_code}","#{place.place_name}","#{church_name}",
                "#{rec.register_entry_number}","#{rec.marriage_date}","#{rec.groom_forename}","#{rec.groom_surname}","#{rec.groom_age}","#{rec.groom_parish}",
                "#{rec.groom_condition}","#{rec.groom_occupation}","#{rec.groom_abode}","#{rec.bride_forename}","#{rec.bride_surname}","#{rec.bride_age}",
                "#{rec.bride_parish}","#{rec.bride_condition}","#{rec.bride_occupation}","#{rec.bride_abode}","#{rec.groom_father_forename}","#{rec.groom_father_surname}",
                "#{rec.groom_father_occupation}","#{rec.bride_father_forename}","#{rec.bride_father_surname}","#{rec.bride_father_occupation}",
                "#{witness1[0]}","#{witness1[1]}","#{witness2[0]}","#{witness2[1]}","#{rec.notes}#{note}"]
    csv_hold = csv_hold + ["#{rec.film}", "#{rec.film_number}"] if file.lds =='yes'
    return csv_hold
  end

  def self.update_location(file,param,myown)
    old_location = file.old_location
    if param[:place] == "Select Place" || param[:church_name] == "Select Church" || param[:county] == "Select County"
      return[true, "You must make a selection"]
    end
    #deal with absent county
    param[:county] = old_location[:place].chapman_code if param[:county].blank?
    update_county = true
    update_county = false if  param[:county] == old_location[:place].chapman_code
    new_location = file.new_location(param)
    file.update_attributes(:place => param[:place], :church_name => param[:church_name], :register_type => param[:register_type],
                           :county => param[:county],:alternate_register_name => new_location[:register].alternate_register_name,
                           :register_id => new_location[:register]._id,)
    if myown
      file.update_attribute(:locked_by_transcriber, true)
    else
      file.update_attribute(:locked_by_coordinator, true)
    end
    new_location[:place].update_attribute(:data_present, true)
    new_location[:place].recalculate_last_amended_date
    file.propogate_file_location_change(new_location)
    PlaceCache.refresh(param[:county]) unless old_location[:place] == new_location[:place]
    return[false,""]
  end
  def propogate_file_location_change(new_location)
    location_names =[]
    place_name = new_location[:place].place_name
    church_name = new_location[:church].church_name
    register_type = RegisterType.display_name(new_location[:register].register_type)
    location_names << "#{place_name} (#{church_name})"
    location_names  << " [#{register_type}]"
    self.freereg1_csv_entries.no_timeout.each do |entry|
      if entry.search_record.nil?
        logger.info "FREEREG:search record missing for entry #{entry._id}"
      else
        entry.update_attributes(:place => place_name, :church_name => church_name)
        record = entry.search_record
        record.update_attributes(:location_names => location_names, :chapman_code => new_location[:county])

        if record.place_id != new_location[:place]._id
          record.update_attribute(:place_id, new_location[:place]._id)
        end
      end
    end
  end
  def old_location
    old_register = self.register
    old_church = old_register.church
    old_place = old_church.place
    location = {:register => old_register, :church => old_church, :place => old_place}
  end

  def new_location(param)
    new_place = Place.where(:chapman_code => param[:county],:place_name => param[:place],:disabled => 'false', :error_flag.ne => "Place name is not approved").first
    new_church = Church.where(:place_id =>  new_place._id, :church_name => param[:church_name]).first
    if  new_church.nil?
      new_church = Church.new(:place_id =>  new_place._id,:church_name => param[:church_name],:place_name => param[:place])  if  new_church.nil?
    end
    number_of_registers = new_church.registers.count
    new_alternate_register_name = param[:church_name].to_s + ' ' + param[:register_type].to_s
    if number_of_registers == 0
      new_register = Register.new(:church_id => new_church._id,:alternate_register_name => new_alternate_register_name, :register_type => param[:register_type])

    else
      if Register.where(:church_id => new_church._id,:alternate_register_name => new_alternate_register_name, :register_type => param[:register_type]).count == 0
        new_register = Register.new(:church_id => new_church._id,:alternate_register_name => new_alternate_register_name, :register_type =>param[:register_type])
      else
        new_register = Register.where(:church_id => new_church._id, :alternate_register_name => new_alternate_register_name, :register_type => param[:register_type]).first
      end
    end
    new_register.freereg1_csv_files << self unless new_register._id == self.register_id
    new_register.save
    new_church.registers << new_register unless new_church._id == new_register.church_id
    new_church.save
    new_place.churches << new_church unless new_place._id == new_church.place_id
    new_place.save
    location = {:register => new_register, :church => new_church, :place => new_place, :county =>param[:county]}
  end

  def date_change(transcription_date,modification_date)
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

  def clean_up
    self.update_number_of_files
    register = self.register
    if register.nil?
      logger.warn("FREEREG:#{self.id} does not belong to a register ")
      return
    else
      church = register.church
      if church.nil?
        logger.warn( "FREEREG:#{register.id} does not belong to a church ")
        return
      else
        place = church.place
        if place.nil?
          logger.warn( "FREEREG:#{church.id} does not belong to a place ")
          return
        else
          place.recalculate_last_amended_date
        end
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



  def update_number_of_files
    #this code although here and works produces values in fields that are no longer being used
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
    #TODO need to recompute max, min and range
    unless added_records == 0
      logger.info "FREEREG:update record count #{self.records.to_i} and #{added_records}"
      records = self.records.to_i + added_records
      self.update_attributes(:records => records.to_s,:locked_by_coordinator => true )
      logger.info "FREEREG:updated record count #{self.records.to_i} "
    end
    return [false, ""]
  end

  def lock(type)
    batches = Freereg1CsvFile.where(:file_name => self.file_name, :userid => self.userid).all
    set_transciber_lock = !self.locked_by_transcriber
    set_coordinator_lock = !self.locked_by_coordinator
    batches.each do |batch|
      if  type
        #transcriber is changing their lock
        batch.update_attributes(:locked_by_transcriber => set_transciber_lock)
      else
        #coordinator is changing locks
        batch.update_attributes(:locked_by_coordinator => set_coordinator_lock)
        batch.update_attributes(:locked_by_transcriber => false) unless set_coordinator_lock
      end
    end
  end

  def lock_all(type)
    batches = Freereg1CsvFile.where(:file_name => self.file_name, :userid => self.userid).all
    batches.each do |batch|
      if  type
        #transcriber is changing their lock
        batch.update_attributes(:locked_by_transcriber => true)
      else
        #coordinator is changing locks
        batch.update_attributes(:locked_by_coordinator => true)
      end
    end
  end

  def force_unlock
    batches = Freereg1CsvFile.where(:file_name => self.file_name, :userid => self.userid).all
    batches.each do |batch|
      batch.update_attributes(:locked_by_coordinator => false)
      batch.update_attributes(:locked_by_transcriber => false)
    end
  end

  def check_locking_and_set(param,sess)
    if sess[:my_own]
      self.update_attributes(:locked_by_transcriber => true)
    else
      self.update_attributes(:locked_by_coordinator => true)
    end
  end

  def self.delete_userid(userid)
    folder_location = File.join(Rails.application.config.datafiles,userid)
    change_folder_location = File.join(Rails.application.config.datafiles_changeset,userid)
    FileUtils.remove_dir(folder_location, :force => true)
    FileUtils.remove_dir(change_folder_location, :force => true)
  end

  def are_we_changing_location?(param)
    change = false
    change = true unless param[:register_type] == self.register_type
    change = true unless param[:church_name] == self.church_name
    change = true unless param[:place] == self.place
    change
  end

  def old_place
    reg_id = self.register_id
    church_id = Register.find(reg_id).church_id
    old_place_id = Church.find(church_id).place_id
  end


  def self.change_userid(id,old_userid, new_userid)
    success = true
    @message = ""
    new_folder_location = File.join(Rails.application.config.datafiles,new_userid)
    old_folder_location = File.join(Rails.application.config.datafiles,old_userid)
    new_change_folder_location = File.join(Rails.application.config.datafiles_changeset,new_userid)
    old_change_folder_location = File.join(Rails.application.config.datafiles_changeset,old_userid)
    if Dir.exist?(new_folder_location)
      @message = "Folder with that name already exists for #{new_userid} in the base"
      success = false
    else
      Dir.mkdir(new_folder_location,0774)
    end
    if Dir.exist?(new_change_folder_location)
      @message = "Folder with that name already exists for #{new_userid} in the change set"
      success = false
    else
      Dir.mkdir(new_change_folder_location,0774)
    end
    if Dir.exist?(old_folder_location) && success
      Dir.glob(File.join(old_folder_location, '*')).each do |file|
        FileUtils.move file, File.join(new_change_folder_location, File.basename(file))
      end
      FileUtils.remove_dir(old_folder_location, :force => true,:verbose => true)
    end
    if Dir.exist?(old_change_folder_location) && success
      Dir.glob(File.join(old_change_folder_location, '*')).each do |file|
        FileUtils.move file, File.join(new_folder_location, File.basename(file))
      end
      FileUtils.remove_dir(old_change_folder_location, :force => true,:verbose => true)
    end
    if success
      userid = UseridDetail.userid(old_userid).first
      userid.update_attribute(:userid,new_userid)
      userid.write_userid_file
      files = Freereg1CsvFile.where(:userid_detail_id => id).all
      files.each do |file|
        physical_file = PhysicalFile.userid(old_userid).file_name(file.file_name).first
        physical_file.update_userid(new_userid) if physical_file.present?
        file.promulgate_userid_change(new_userid,old_userid)
      end
    end
    return[success,@message]
  end

  def move_file_between_userids(new_userid)
    #first step is to move the files
    old_userid = self.userid
    success = true
    message = ""
    new_folder_location = File.join(Rails.application.config.datafiles,new_userid)
    old_folder_location = File.join(Rails.application.config.datafiles,old_userid)
    new_change_folder_location = File.join(Rails.application.config.datafiles_changeset,new_userid)
    old_change_folder_location = File.join(Rails.application.config.datafiles_changeset,old_userid)
    if Dir.exist?(new_folder_location)
      if Dir.exist?(old_folder_location)
        old_file_location = File.join(Rails.application.config.datafiles,old_userid,self.file_name)
        self.save_to_attic
        self.write_csv_file(old_file_location)
        result = self.move_fr2_file(new_userid,old_userid,self.file_name)
        message = result[1]
        return[result[0],result[1]] if !result[0]
      else
        success = false
        message = "No FR2 folder for the old userid"
      end
      if Dir.exist?(new_change_folder_location)
        if Dir.exist?(old_change_folder_location)
          result = self.move_fr1_file(new_userid,old_userid,self.file_name)
          message = result[1]
          return[result[0],result[1]] if !result[0]
        else
          success = true
          message= "No FR1 folder for the old userid"
        end
      else
        message = "No FR1 folder for the new userid"
        success = true
      end
    else
      message = "No FR2 folder for the new userid"
      success = false
    end
    if success
      #now we update the system information
      physical_file = PhysicalFile.userid(old_userid).file_name(self.file_name).first
      if physical_file.present?
        physical_file.update_userid(new_userid)
        if message == "No FR1 folder for the old userid" || message == message = "No FR1 folder for the new userid"
          physical_file.update_change(new_userid)
        end
      end
      self.promulgate_userid_change(new_userid,old_userid)
    end
    return[success,message]
  end
  def move_fr2_file(new_userid,old_userid,file_name)
    success = true
    message = ""
    new_file_location = File.join(Rails.application.config.datafiles,new_userid,file_name)
    new_folder_location = File.join(Rails.application.config.datafiles,new_userid)
    old_file_location = File.join(Rails.application.config.datafiles,old_userid,file_name)
    if File.file?(old_file_location)
      if  File.file?(new_file_location)
        success = false
        message = "File already exists in FR2 folder for the new userid"
      else
        FileUtils.mv(old_file_location, new_folder_location, :force => true,:verbose => true)
        FileUtils.remove(old_file_location, :force => true,:verbose => true) if File.exist?(old_file_location)
      end
    else
      message = "File does not exist in FR2 folder for the old userid"
    end
    return[success,message]
  end
  def move_fr1_file(new_userid,old_userid,file_name)
    success = true
    message = ""
    new_file_location = File.join(Rails.application.config.datafiles_changeset,new_userid,file_name)
    new_folder_location = File.join(Rails.application.config.datafiles_changeset,new_userid)
    old_file_location = File.join(Rails.application.config.datafiles_changeset,old_userid,file_name)
    if File.file?(old_file_location)
      if File.file?(new_file_location)
        success = false
        message = "File already exists in FR1 folder for the new userid"
      else
        FileUtils.cp(old_file_location, new_folder_location, :verbose => true)
        #must not remove the old file or the rsync will add it back
        #FileUtils.remove(old_file_location, :force => true,:verbose => true) if File.exist?(old_file_location)
      end
    else
      success = true
      message = "File does not exist in FR1 folder for the old userid"
    end
    return[success,message]
  end
  def promulgate_userid_change(new_userid,old_userid)
    #since a file may have many batches we must change them all as we have moved the file
    batches = Freereg1CsvFile.userid(old_userid).file_name(self.file_name).all
    batches.each do |batch|
      success = batch.update_entries_userid(new_userid)
      batch.update_attributes(:userid => new_userid, :userid_lower_case => new_userid.downcase) if success
      batch.update_userids_with_change(new_userid) if success
    end
  end
  def update_userids_with_change(new_userid)
    new_userid_detail = UseridDetail.userid(new_userid).first
    self.update_attribute(:userid_detail_id,new_userid_detail.id)
  end
  def update_entries_userid(userid)
    self.freereg1_csv_entries.each do |entry|
      line = entry.line_id
      if line.present?
        line_parts = line.split('.')
        line_parts[0] = userid
        line = line_parts.join('.')
      else
        line = (userid + "." + self.file_name + "." + entry.file_line_number.to_s).to_s
      end
      entry.update_attribute(:line_id,line)
    end
    true
  end
  def calculate_distribution
    daterange = Array.new(50){|i| i * 0 }
    number_of_records = 0
    datemax = FreeregValidations::YEAR_MIN
    datemin = FreeregValidations::YEAR_MAX
    self.freereg1_csv_entries.each do |entry|
      xx = entry.year
      if xx.present? && entry.enough_name_fields?
        xx = entry.year.to_i
        datemax = xx if xx > datemax && xx < FreeregValidations::YEAR_MAX
        datemin = xx if xx < datemin
        bin = ((xx-FreeregOptionsConstants::DATERANGE_MINIMUM)/10).to_i
        bin = 0 if bin < 0
        bin = 49 if bin > 49
        daterange[bin] = daterange[bin] + 1
      end
      number_of_records =  number_of_records + 1
    end
    self.update_attributes(:datemin => datemin,:datemax => datemax,:daterange => daterange,:records =>  number_of_records )
    success = true
    success = false if self.errors.any?
    return success
  end
  def calculate_date(param)
    case
      when self.record_type == 'ba'
        date = param[:freereg1_csv_entry][:baptism_date]  
        date = param[:freereg1_csv_entry][:birth_date] if param[:freereg1_csv_entry][:baptism_date].nil? 
      when self.record_type == 'ma'
        date = param[:freereg1_csv_entry][:marriage_date]
      when self.record_type == 'bu'
        date = param[:freereg1_csv_entry][:burial_date]
    end
    date = FreeregValidations.year_extract(date)
    unless date.nil?
      date = date.to_i
      self.datemax = date if date > self.datemax.to_i && date < FreeregValidations::YEAR_MAX
      @self.datemin = date if date < self.datemin.to_i
      bin = ((date - FreeregOptionsConstants::DATERANGE_MINIMUM)/10).to_i 
        bin = 0 if bin < 0
        bin = 49 if bin > 49
        self.daterange[bin] = self.daterange[bin] + 1
      end
    end
    def define_colour
      #need to consider storing the processed rather than a look up
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
    def self.unique_names(names)
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
    def add_to_rake_delete_list
      processing_file = Rails.application.config.delete_list
      File.open(processing_file, 'a') do |f|
        f.write("#{self.id},#{self.userid},#{self.file_name}\n")
      end
    end
    def remove_batch
      if self.locked_by_transcriber  ||  self.locked_by_coordinator
        return false,'The removal of the batch was unsuccessful; the batch is locked'
      else
        #deal with file and its records
        self.add_to_rake_delete_list
        self.save_to_attic
        self.delete
        #deal with the Physical Files collection
        physical_file = PhysicalFile.userid(self.userid).file_name(self.file_name).first
        if physical_file.present?
          physical_file.remove_processed_flag
          physical_file.remove_base_flag
          physical_file.destroy if physical_file.empty?
        end
        return true, 'The removal of the batch entry was successful'
      end
    end
  end
