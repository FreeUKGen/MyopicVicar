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
  field :county, type: String #note in headers this is actually a chapman code
  field :place, type: String
  field :church_name, type: String
  field :register_type, type: String
  field :record_type, type: String#, :in => RecordType::ALL_TYPES+[nil]
  validates_inclusion_of :record_type, :in => RecordType::ALL_TYPES+[nil]
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
  field :locked_by_transcriber, type: String, default: 'false'
  field :locked_by_coordinator, type: String, default: 'false'
  field :lds, type: String, default: 'no'
  field :action, type: String
  field :characterset, type: String
  field :alternate_register_name, type: String
  field :csvfile, type: String



  index({file_name:1,userid:1,county:1,place:1,church_name:1,register_type:1})
  index({county:1,place:1,church_name:1,register_type:1, record_type: 1})
  index({file_name:1,error:1})
  index({error:1, file_name:1})

before_save :add_lower_case_userid
after_save :recalculate_last_amended, :update_number_of_files
before_destroy do |file|
    file.save_to_attic
    Freereg1CsvEntry.destroy_all(:freereg1_csv_file_id => file._id)
end

 after_destroy :clean_up

  has_many :freereg1_csv_entries, validate: false
  belongs_to :register, index: true
  #register belongs to church which belongs to place
  has_one :csvfile
  has_many :batch_errors
   
  scope :syndicate, ->(syndicate) { where(:transcriber_syndicate => syndicate) }
 scope :county, ->(county) { where(:county => county) }
 scope :userid, ->(userid) { where(:userid => userid) }
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
    #needs review
     hold_combined_files = Array.new
     hold_file_ba = Freereg1CsvFile.new(:record_type => "ba")
     hold_file_bu = Freereg1CsvFile.new(:record_type => "bu")
     hold_file_ma = Freereg1CsvFile.new(:record_type => "ma")
     nm = 0
     nba = 0
     nbu = 0

    all_files.each do |individual_file|
      case
       when individual_file.record_type == "ba"
        combine_now(hold_file_ba,individual_file,nba)
        nba = nba + 1
       when individual_file.record_type == "bu"
        combine_now(hold_file_bu,individual_file,nbu)
        nbu = nbu + 1
       when individual_file.record_type == "ma"
         combine_now(hold_file_ma,individual_file,nm)
        nm = nm + 1
      end
    end
    hold_combined_files << hold_file_ba
    hold_combined_files << hold_file_bu
    hold_combined_files << hold_file_ma
  end
   
  def self.combine_now(hold_file,individual_file,n)
     #needs review
      if n == 0
               hold_file.records = individual_file.records
               hold_file.datemax = individual_file.datemax
               hold_file.datemin = individual_file.datemin
               hold_file.daterange = individual_file.daterange
               hold_file.transcriber_name = individual_file.transcriber_name
               hold_file.credit_name = individual_file.credit_name
               hold_file.transcription_date = individual_file.transcription_date
               hold_file.modification_date = individual_file.modification_date
      else
               hold_file.records = individual_file.records.to_i + hold_file.records.to_i
               hold_file.datemax = individual_file.datemax if individual_file.datemax > hold_file.datemax
               hold_file.datemin = individual_file.datemin if individual_file.datemin < hold_file.datemin
               if hold_file.transcriber_name.nil?
                 hold_file.transcriber_name = individual_file.transcriber_name
               else
                unless individual_file.transcriber_name.nil?
                hold_file.transcriber_name = hold_file.transcriber_name + ", " + individual_file.transcriber_name unless (hold_file.transcriber_name == individual_file.transcriber_name)
                end
               end
               if hold_file.credit_name.nil?
                 hold_file.credit_name = individual_file.transcriber_name
               else
                unless individual_file.credit_name.nil?
                hold_file.credit_name = hold_file.credit_name + ", " + individual_file.credit_name unless (hold_file.credit_name == individual_file.credit_name)
                end
               end
                          
                 hold_file.daterange.each_index do |i|
                   hold_file.daterange[i] = hold_file.daterange[i].to_i + individual_file.daterange[i].to_i

                 end
               hold_file.transcription_date = individual_file.transcription_date if (Freereg1CsvFile.convert_date(individual_file.transcription_date) < Freereg1CsvFile.convert_date(hold_file.transcription_date))
               hold_file.modification_date = individual_file.modification_date if (Freereg1CsvFile.convert_date(individual_file.modification_date) > Freereg1CsvFile.convert_date(hold_file.modification_date))
                   
      end

      hold_file
  end
def self.delete_file(file)
      Freereg1CsvFile.where(:userid => file.userid, :file_name => file.file_name).all.each do |f|
      f.save_to_attic
      Freereg1CsvEntry.destroy_all(:freereg1_csv_file_id => file._id)  
      f.delete
     end
end
  
  def save_to_attic
    #to-do unix permissions
   file = self.file_name
   file_location = File.join(Rails.application.config.datafiles,self.userid,file)
      if File.file?(file_location)
        newdir = File.join(File.join(Rails.application.config.datafiles,self.userid),'.attic')
        Dir.mkdir(newdir) unless Dir.exists?(newdir)
        renamed_file = (file_location + "." + (Time.now.to_i).to_s).to_s
        File.rename(file_location,renamed_file)
        FileUtils.mv(renamed_file,newdir,:verbose => true)
       else
         p "file does not exist"
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
  def backup_file
    #this makes aback up copu of the file in the attic and
    file = self
    file.save_to_attic
    file_name = file.file_name
       #since there can be multiple places/churches in a single file we must combine the records for all those back into the single file
    file_parts = Freereg1CsvFile.where(:file_name => file_name, :userid => file.userid).all
    file_location = File.join(Rails.application.config.datafiles,file.userid,file_name)
    CSV.open(file_location, "wb", {:force_quotes => true, :row_sep => "\r\n"}) do |csv|
        # eg +INFO,David@davejo.eclipse.co.uk,password,SEQUENCED,BURIALS,cp850,,,,,,,
    record_type = RecordType.display_name(file.record_type).upcase + 'S'
    csv << ["+INFO","#{file.transcriber_email}","PASSWORD","SEQUENCED","#{record_type}","#{file.characterset}"]
      # eg #,CCCC,David Newbury,Derbyshire,dbysmalbur.CSV,02-Mar-05,,,,,,,
    csv << ['#','CCCC',file.transcriber_name,file.transcriber_syndicate,file.file_name,file.transcription_date]
      # eg #,Credit,Libby,email address,,,,,,
    csv << ['#','CREDIT',file.credit_name,file.credit_email]
       # eg #,05-Feb-2006,data taken from computer records and converted using Excel, LDS
    csv << ['#',file.modification_date,file.first_comment,file.second_comment]
       #eg +LDS,,,,
    csv << ['+LDS'] if file.lds =='yes'
    file_parts.each do |fil|
    type = fil.record_type
    records = fil.freereg1_csv_entries
      records.each do |rec|
        church_name = fil.church_name.to_s + " " + fil.register_type.to_s
       case
         when fil.record_type == "ba"
         
            csv_hold = ["#{fil.county}","#{fil.place}","#{church_name}",
             "#{rec.register_entry_number}","#{rec.birth_date}","#{rec.baptism_date}","#{rec.person_forename}","#{rec.person_sex}",
             "#{rec.father_forename}","#{rec.mother_forename}","#{rec.father_surname}","#{rec.mother_surname}","#{rec.person_abode}",
             "#{rec.father_occupation}","#{rec.notes}"]
            csv_hold = csv_hold + ["#{rec.film}", "#{rec.film_number}"] if fil.lds =='yes'
            csv << csv_hold

         when fil.record_type == "bu"
           
            csv_hold = ["#{fil.county}","#{fil.place}","#{church_name}",
            "#{rec.register_entry_number}","#{rec.burial_date}","#{rec.burial_person_forename}",
            "#{rec.relationship}","#{rec.male_relative_forename}","#{rec.female_relative_forename}","#{rec.relative_surname}",
            "#{rec.burial_person_surname}","#{rec.person_age}","#{rec.burial_person_abode}","#{rec.notes}"]
            csv_hold = csv_hold + ["#{rec.film}", "#{rec.film_number}"] if fil.lds =='yes'
            csv << csv_hold
        
         when fil.record_type == "ma"
          csv_hold = ["#{fil.county}","#{fil.place}","#{church_name}",
          "#{rec.register_entry_number}","#{rec.marriage_date}","#{rec.groom_forename}","#{rec.groom_surname}","#{rec.groom_age}","#{rec.groom_parish}",
          "#{rec.groom_condition}","#{rec.groom_occupation}","#{rec.groom_abode}","#{rec.bride_forename}","#{rec.bride_surname}","#{rec.bride_age}",
          "#{rec.bride_parish}","#{rec.bride_condition}","#{rec.bride_occupation}","#{rec.bride_abode}","#{rec.groom_father_forename}","#{rec.groom_father_surname}",
          "#{rec.groom_father_occupation}","#{rec.bride_father_forename}","#{rec.bride_father_surname}","#{rec.bride_father_occupation}",
          "#{rec.witness1_forename}","#{rec.witness1_surname}","#{rec.witness2_forename}","#{rec.witness2_surname}","#{rec.notes}"]
            csv_hold = csv_hold + ["#{rec.film}", "#{rec.film_number}"] if fil.lds =='yes'
            csv << csv_hold
       end #end case
     end #end records
    end #file parts

    end #end csv
   end #end method

def self.update_location(file,param)
  old_location = file.old_location
  #deal with absent county
  param[:county] = old_location[:place].chapman_code if param[:county].nil? || param[:county].empty?
  new_location = file.new_location(param)
  file.update_attributes(:place => param[:place], :church_name => param[:church_name], :register_type => param[:register_type],
  :county => param[:county],:alternate_register_name => new_location[:register].alternate_register_name,:register_id => new_location[:register]._id)
  new_location[:register].save(:validate => false) unless old_location[:register] == new_location[:register]
  new_location[:church].save(:validate => false) unless old_location[:church] == new_location[:church]
  new_location[:place].save(:validate => false)unless old_location[:place] == new_location[:place] 
  param[:place_id] = new_location[:place]._id
  file.update_entries_and_search_records(param)  
  file.backup_file
  Register.clean_empty_registers(old_location[:register]) unless old_location[:register] == new_location[:register] 
  file
end

def old_location
  old_file_id = self._id
  old_register = self.register
  old_church_id = old_register.church_id
  old_church = old_register.church
  old_place_id = Church.find(old_church_id).place_id
  old_place = old_church.place
  location = {:register => old_register, :church => old_church, :place => old_place}
end
def new_location(param)
  p self
  new_place = Place.where(:chapman_code => param[:county],:place_name => param[:place],:disabled => 'false').first
  new_church = Church.where(:place_id =>  new_place._id, :church_name => param[:church_name]).first
  if  new_church.nil?
    new_church = Church.new(:place_id =>  new_place._id,:church_name => param[:church_name],:place_name => param[:place])  if  new_church.nil?
    new_church.save
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
  new_register.save
  p new_register
  location = {:register => new_register, :church => new_church, :place => new_place}
end

def update_entries_and_search_records(param)
   self.freereg1_csv_entries.each do |entry|
   entry.update_attributes(:county => param[:county],:place =>param[:place],:register_type => param[:register_type])
   entry.search_record.update_attributes(:place_id => param[:place_id],:chapman_code => param[:county], :location_name =>"#{param[:place]} (#{param[:church_name]})")
  end
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
    register = self.register
    church = register.church
    place = church.place
    Register.clean_empty_registers(register)
    Place.recalculate_last_amended_date(place)
  end

  def recalculate_last_amended
     register = self.register
     return if register.nil?
     church = register.church
     place = church.place
     Place.recalculate_last_amended_date(place)
  end

 
 def update_number_of_files
#need to think about doing an update
   userid = UseridDetail.where(:userid_lower_case => self.userid.downcase).first
   files = Freereg1CsvFile.where(:userid_lower_case => self.userid.downcase).all
 
    if files.nil?
     userid.number_of_files = 0
     userid.number_of_records = 0
     userid.last_upload = nil
    else
     number = 0
     records = 0
      files.each do |my_file|
       
        number  = number  + 1
        records = records + my_file.records.to_i

        userid.last_upload  = my_file.uploaded_date if number == 1
          unless my_file.uploaded_date.nil? || userid.last_upload .nil?
           userid.last_upload  = my_file.uploaded_date if my_file.uploaded_date.strftime("%s").to_i > userid.last_upload.strftime("%s").to_i
          end
       end
       userid.set(:number_of_files  => number)
       userid.set(:number_of_records => records)
     
    end
 end
def lock(type)
  if  type == 'my_own'
     if  self.locked_by_transcriber == 'false'
      self.update_attributes(:locked_by_transcriber => 'true')
     else
      self.update_attributes(:locked_by_transcriber => 'false')
     end
    else 
     if  self.locked_by_coordinator == 'false'
       self.update_attributes(:locked_by_coordinator => 'true')
     else
       self.update_attributes(:locked_by_coordinator => 'false')
     end
    end
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

def check_locking_and_set(param,sess)
    unless ((self.locked_by_transcriber == "true" && param[:locked_by_transcriber] == "false") ||  (self.locked_by_coordinator == "true"  &&  param[:locked_by_coordinator]  == "false"))
      self.update_attributes(:locked_by_transcriber => "true") if sess[:my_own] == 'my_own' 
      self.update_attributes(:locked_by_coordinator => "true") unless sess[:my_own] == 'my_own'
    end 
end

end

