Freereg2 Database and Fields(Jan/2014)

Our current data model for Freereg2 starts with a Place in a specific County. A Place can have many religious institutions which we call Churches. Each Church can have many Registers.  Each Register can have many Freereg Files.  Each Freereg File has many Entries. Each Entry has a single Search Record which contains the information required for an effective search. 

Collections/tables that are used to support this model are 1) Chapman Codes 2) Master Place Name and perhaps an associated Alias Place Church. 3) Emendation Rules 4) Person Details* 5)Syndicates 
(*This is a collection of information on people and their coordinates ie userid, email address, physical address, etc plus their role which code be researcher, transcriber, coordinator, assistant coordinator, system administrator, data manager; the collection replaces the more limited transcriber table in F1)

There is a data model associated with on-line Image transcription that will link into Registers and also provide a set of Entries and Search Records
These collections/tables are currently filled by processing the CSV files and from on-line transcriptions. i.e. they are filled from the bottom up. This means that at this point in time the database for Places and everything below it only contain information on which we have transcriptions. This WILL change.

Place Fields;
field :chapman_code, type: String#, :required => true
field :place_name, type: String#, :required => true
field :last_amended, type: String
field :alternate_place_name, type: String
field :place_notes, type: String
field :genuki_url, type: String
field :master_place_lat, type: String
field :master_place_lon, type: String
field :location, type: Array
has_many :churches
has_many :search_records
Church Fields:
field :church_name,type: String
field :last_amended, type: String
field :denomination, type: String
field :location, type: Array
field :alternate_church_name, type: String
field :church_notes, type: String
has_many :registers
belongs_to :place, index: true
Register Fields:
field :status, type: String
field :register_name, type: String
field :alternate_register_name, type: String
field :register_type, type: String
field :quality, type: String
field :source, type: String
field :copyright, type: String
field :register_notes, type: String
field :last_amended, type: String
has_many :freereg1_csv_files
belongs_to :church, index: true

Freereg1CSVFile Fields
field :county, type: String
  field :place, type: String
  field :church_name, type: String
  field :register_type, type: String
  field :record_type, type: String#, :in => RecordType::ALL_TYPES+[nil]
  field :records, type: String
  field :datemin, type: String
  field :datemax, type: String
  field :daterange, type: Array
  field :userid, type: String
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
  field :digest, type: String
  field :locked, type: String, default: -> {false}
  field :lds, type: String
  field :characterset, type: String
  field :alternate_register_name, type: String
has_many :freereg1_csv_entries
belongs_to :register, index: true

Freereg1CsvEntries Fields
field :baptism_date, type: String #actual date as written
  field :birth_date, type: String #actual date as written
  field :bride_abode, type: String
  field :bride_age, type: String
  field :bride_condition, type: String
  field :bride_father_forename, type: String
  field :bride_father_occupation, type: String
  field :bride_father_surname, type: String
  field :bride_forename, type: String
  field :bride_occupation, type: String
  field :bride_parish, type: String
  field :bride_surname, type: String
  field :burial_date, type: String #actual date as written
  field :burial_person_forename, type: String
  field :burial_person_surname, type: String
  field :burial_person_abode, type: String
  field :county, type: String
  field :father_forename, type: String
  field :father_occupation, type: String
  field :father_surname, type: String
  field :female_relative_forename, type: String
  field :groom_abode, type: String
  field :groom_age, type: String
  field :groom_condition, type: String
  field :groom_father_forename, type: String
  field :groom_father_occupation, type: String
  field :groom_father_surname, type: String
  field :groom_forename, type: String
  field :groom_occupation, type: String
  field :groom_parish, type: String
  field :groom_surname, type: String
  field :male_relative_forename, type: String
  field :marriage_date, type: String #actual date as written
  field :mother_forename, type: String
  field :mother_surname, type: String
  field :notes, type: String
  field :person_abode, type: String
  field :person_age, type: String
  field :person_forename, type: String
  field :person_sex, type: String
  field :place, type: String
  field :register, type: String
  field :register_entry_number, type: String
  field :register_type, type: String
  field :relationship, type: String
  field :relative_surname, type: String
  field :witness1_forename, type: String
  field :witness1_surname, type: String
  field :witness2_forename, type: String
  field :witness2_surname, type: String
  field :line_id, type: String
  field :file_line_number, type: Integer
belongs_to :freereg1_csv_file, index: true
 has_one :search_record

SearchRecord Fields
 field :annotation_ids, type: Array 
 field :asset_id, type: String
  field :chapman_code, type: String
  field :record_type, type: String
  field :transcript_names, type: Array#, :required => true
  field :transcript_date, type: String#, :required => false
 field :search_date, type: String#, :required => false
embeds_many :search_names, :class_name => 'SearchName'
 field :search_soundex, type: Array, default: []
belongs_to :freereg1_csv_entry, index: true
belongs_to :place, index:true

ImageUpload Fields
field :name, type: String
  field :upload_path, type: String
    field :working_dir, type: String
  field :originals_dir, type: String
  field :derivation_dir, type: String
  field :total_files, type: String
  field :downloaded, type: Integer
has_many :image_dir
  has_many :image_upload_log
  
Image List Fields
field :name, type: String#, :required => true
  field :chapman_code, type: String#, :required => false, :in => ChapmanCode::values+[nil]
  field :start_date, type: String#, :length=>10
  field :end_date, type: String#, :length=>10
  field :difficulty
  field :image_file_ids, type: Array #, :typecast => 'ObjectId'
  field :template, type: BSON::ObjectId
  field :asset_collection, type: BSON::ObjectId
has_many :image_files, :as => :image_file_ids
ImageDir Fields
field :name, type: String
field :path, type: String

belongs_to :upload
has_many :image_file

ImageFile Fields

  field :name, type: String
  
  field :original_name, type: String

  field :path, type: String
  
  field :width, type: Integer
 
 field :height, type: Integer

  field :thumbnail_width, type: Integer
  field :thumbnail_height, type: Integer

belongs_to :image_dir

has_many :image_files, :as => :image_file_ids

NOTES

1) The location information in the Places collection (which was not part of F1) is obtained by searching the Master Place Name collection for a Place with the same place name. i.e. the places names in the two collections Place and Master need to be the same for us to find the location. 

The Researcher Search is done against the search records in the database. It asks the user to specify the counties of interest and the Places within those counties using the place name field.
2)The DAP displays for the researcher information on the number of records and range of years for that data held in the database for each register of a church for a place within a county. It displays place name, church name and register names as well as the alternate name fields and the last amended dates.
Both the Search and DAP therefore use the Place collection and its place name. 
3)Technically then we only "need" the Master to hold those place names we are using. However I asked that we keep in the Master the place names and locations for additional places for 2 reasons 1) so that we can match new transcription place names and get their locations 2) use the place name in the Master to validate new incoming transcription files and avoid amassing problems for the future 3) use as the basis for the RAP and 4) for selection of place names for on-line transcription.
4) The current database holds information on 6,393 distinct places; 8,956 churches, 10,215 registers, 35,272 files and 26,243,918 entries and search records and occupies 17.7GB of storage.
