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
  # require 'csvfile'
   require 'csv'


  has_many :freereg1_csv_entries, validate: false
  belongs_to :register, index: true
  #register belongs to church which belongs to place
  has_one :csvfile
  has_many :batch_errors
  


  # Fields correspond to cells in CSV headers  
  field :county, type: String 
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
  field :alternate_register_name,  type: String
  field :csvfile, type: String



  index({file_name:1,userid:1,county:1,place:1,church_name:1,register_type:1})
  index({county:1,place:1,church_name:1,register_type:1, record_type: 1})
index({file_name:1,error:1})
index({error:1, file_name:1})
  before_save :add_lower_case_userid
  after_save :create_or_update_last_amended_date 
  
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





  def create_or_update_last_amended_date
   
   Register.create_or_update_last_amended_date(self)
  
   Church.create_or_update_last_amended_date(self)
   
   UseridDetail.update_files(self)
   
  end

  def add_lower_case_userid
 
    self[:userid_lower_case] = self[:userid].downcase
  end

 

  def ordered_display_fields
    order = []
 #   order << 'county'
 #   order << 'place'
    order << 'register'
    order << 'register_type'
    order << 'record_type'
    order << 'file_name'
#    order << 'transcriber_name'
    order << 'transcriber_syndicate'
#    order << 'credit_name'
    order << 'first_comment'
    order << 'second_comment'

    order
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
    
    hold_combined_files <<  hold_file_ba
    hold_combined_files <<  hold_file_bu
    hold_combined_files <<  hold_file_ma
    
    
  end 
   
  def self.combine_now(hold_file,individual_file,n)
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
              
               hold_file.records = individual_file.records.to_i +  hold_file.records.to_i
               hold_file.datemax = individual_file.datemax if individual_file.datemax >  hold_file.datemax 
               hold_file.datemin = individual_file.datemin if individual_file.datemin <  hold_file.datemin
               if hold_file.transcriber_name.nil? 
                 hold_file.transcriber_name = individual_file.transcriber_name 
               else
                unless individual_file.transcriber_name.nil?
                hold_file.transcriber_name = hold_file.transcriber_name + ", " + individual_file.transcriber_name unless  (hold_file.transcriber_name == individual_file.transcriber_name) 
                end
               end
               if hold_file.credit_name.nil? 
                 hold_file.credit_name = individual_file.transcriber_name 
               else
                unless individual_file.credit_name.nil?
                hold_file.credit_name = hold_file.credit_name + ", " + individual_file.credit_name unless  (hold_file.credit_name == individual_file.credit_name)
                end
               end
                          
                 hold_file.daterange.each_index do |i|
                   hold_file.daterange[i] =  hold_file.daterange[i].to_i + individual_file.daterange[i].to_i

                 end
               hold_file.transcription_date = individual_file.transcription_date if (Freereg1CsvFile.convert_date(individual_file.transcription_date) <  Freereg1CsvFile.convert_date(hold_file.transcription_date))
               hold_file.modification_date = individual_file.modification_date if (Freereg1CsvFile.convert_date(individual_file.modification_date) >  Freereg1CsvFile.convert_date(hold_file.modification_date))
              
               
      end

      hold_file
  end
  def self.delete_file(csv_file)
   
        # add it to a before_delete callback.  (N.B. then use destroy rather than delete from
        # this function)
       
         # fetch the IDs of all the entries on this file
        freereg_entries = Freereg1CsvEntry.where(:freereg1_csv_file_id => csv_file).all
        freereg_entries.each do |entry|
          # now we delete the SearchRecord records that point to any of those entry IDs
          SearchRecord.where(:freereg1_csv_entry_id => entry._id).delete_all
           # now delete the csv entry records
          Freereg1CsvEntry.where(:_id => entry._id).delete_all
        end
       
        # now we can delete the file
       Freereg1CsvFile.where(:_id => csv_file).delete_all
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
        #work with  dd mmm yyyy
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
    my_days =  date_year.to_i*365 + date_month.to_i*30 + date_day.to_i 
    my_days
  end
  def self.backup_file(file)
    #this makes aback up copu of the file in the attic and
  
   file_name = file.file_name
   csvdir = File.join(Rails.application.config.datafiles,file.userid)
   csvfile = File.join(csvdir,file_name)
    
      if File.file?(csvfile)
        newdir = File.join(csvdir,'.attic')
        Dir.mkdir(newdir) unless Dir.exists?(newdir)
        renamed_file = (csvfile + "." + (Time.now.to_i).to_s).to_s
        File.rename(csvfile,renamed_file)
        FileUtils.mv(renamed_file,newdir, verbose:  true)
       else 
         p "file does not exist"
        end
   csv_hold = Array.new
       if File.file?(csvfile)
          p "file should not be there"
       end
       #since there can be multiple places/churches in a single file we must combine the records for all those back into the single file
    file_parts = Freereg1CsvFile.where(:file_name => file_name, :userid => file.userid).all

    CSV.open(csvfile, "wb", {:force_quotes => true}) do |csv|
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
         
            csv_hold =  ["#{fil.county}","#{fil.place}","#{church_name}",
             "#{rec.register_entry_number}","#{rec.birth_date}","#{rec.baptism_date}","#{rec.person_forename}","#{rec.person_sex}",
             "#{rec.father_forename}","#{rec.mother_forename}","#{rec.father_surname}","#{rec.mother_surname}","#{rec.person_abode}",
             "#{rec.father_occupation}","#{rec.notes}"]
            csv_hold =  csv_hold + ["#{rec.film}", "#{rec.film_number}"] if fil.lds =='yes'
            csv << csv_hold

         when fil.record_type == "bu"
           
            csv_hold = ["#{fil.county}","#{fil.place}","#{church_name}",
            "#{rec.register_entry_number}","#{rec.burial_date}","#{rec.burial_person_forename}",
            "#{rec.relationship}","#{rec.male_relative_forename}","#{rec.female_relative_forename}","#{rec.relative_surname}",
            "#{rec.burial_person_surname}","#{rec.person_age}","#{rec.burial_person_abode}","#{rec.notes}"]
            csv_hold =  csv_hold + ["#{rec.film}", "#{rec.film_number}"] if fil.lds =='yes'
            csv << csv_hold
        
         when fil.record_type == "ma" 
          csv_hold = ["#{fil.county}","#{fil.place}","#{church_name}",
          "#{rec.register_entry_number}","#{rec.marriage_date}","#{rec.groom_forename}","#{rec.groom_surname}","#{rec.groom_age}","#{rec.groom_parish}",
          "#{rec.groom_condition}","#{rec.groom_occupation}","#{rec.groom_abode}","#{rec.bride_forename}","#{rec.bride_surname}","#{rec.bride_age}",
          "#{rec.bride_parish}","#{rec.bride_condition}","#{rec.bride_occupation}","#{rec.bride_abode}","#{rec.groom_father_forename}","#{rec.groom_father_surname}",
          "#{rec.groom_father_occupation}","#{rec.bride_father_forename}","#{rec.bride_father_surname}","#{rec.bride_father_occupation}",
          "#{rec.witness1_forename}","#{rec.witness1_surname}","#{rec.witness2_forename}","#{rec.witness2_surname}","#{rec.notes}"]
            csv_hold =  csv_hold + ["#{rec.film}", "#{rec.film_number}"] if fil.lds =='yes'
            csv << csv_hold
       end #end case
     end #end records
    end #file parts

    end #end csv
   end #end method
  def self.update_file_attributes(my_files,attribute,change)
    if my_files then
      my_files.each do |myfile|
        case 
        when attribute == 'place'
          myfile.place = change
        when attribute == 'church'
          myfile.church_name = change
        end
        myfile.locked_by_coordinator = "true"
        myfile.modification_date = Time.now.strftime("%d %b %Y")
        myfile.save!

 # save place name change in Freereg_csv_entry
        myfile_id = myfile._id
        my_entries = Freereg1CsvEntry.where(:freereg1_csv_file_id => myfile_id).all
        my_entries.each do |myentries|
           case 
           when attribute == 'place'
            myentries.place = change
           when attribute == 'church'
            myentries.church_name = change
           end
            myentries.save!
        end #end myentries
          Freereg1CsvFile.backup_file(myfile)
      end #end myfile
    end #end my_files
  end
end
