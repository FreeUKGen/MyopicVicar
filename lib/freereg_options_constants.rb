module FreeregOptionsConstants

  CHAPMAN_CODE_ELIMINATIONS = ['England', 'Scotland', 'Wales','Unknown', 'Clwyd','Dyfed','Gwent','Gwynedd','Powys','Mid Glamorgan',
      'South Glamorgan','West Glamorgan','Borders','Central','Dumfries and Galloway','Grampian','Highland','Lothian','Orkney Isles',
      'Shetland Isles','Strathclyde','Tayside','Western Isles']
  MAXIMUM_NUMBER_OF_RESULTS = 250
  MAXIMUM_NUMBER_OF_SCANS = 500
  DATERANGE_MINIMUM = 1530
  ISSUES = ['General Comment ','Data Question', 'Website Problem','Volunteering Question','Genealogical Question', 'Enhancement Suggestion', 'Thank you' ]
  FORCE_SEARCH_RECORD_RECREATE = [
    "baptism_date", 
    "birth_date", 
    "bride_father_forename", 
    "bride_father_surname", 
    "bride_forename",
    "bride_surname", 
    "burial_date", 
    "burial_person_forename", 
    "burial_person_surname", 
    "father_forename", 
    "father_surname", 
    "female_relative_forename", 
    "groom_father_forename", 
    "groom_father_surname", 
    "groom_forename", 
    "groom_surname", 
    "male_relative_forename", 
    "marriage_date",  
    "mother_forename", 
    "mother_surname", 
    "person_forename", 
    "relative_surname", 
    "witness1_forename", 
    "witness1_surname", 
    "witness2_forename", 
    "witness2_surname"
   ]
  ALPHABET = ["A-C","D-F","G-I","J-L","M-N","O-Q","R-T","U-Z"]
  ALPHABET_SELECTION_LIST = ["CAM","CON","DUR","ESS","GLA","KEN","LAN","LIN","MDX","NBL","NFK","NTH","NTT","SOM","SRY","STS","WRY"]
  ALPHABETS = [
     ["A-Z"], ["A-L","M-Z"], ["A-I","J-O", "P-Z"], ["A-F", "G-L", "M-Q", "R-Z"],["A-D","E-I","J-M","N-R","P-Z"],["A-D","E-H","I-L","M-O","P-S","T-Z"],
     ["A-D","E-G","H-J","K-M","N-P","Q-S","T-Z"],["A-C","D-F","G-I","J-L","M-N","O-Q","R-T","U-Z"],
     ["A-B","C-D","E-F","G-H","I-J","K-L","M-N","O-P","Q-R","S-T","U-V","W-Z"],
     ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q-R","S","T","U-V","W-X","Y-Z"]
  ]
  RECORDS_PER_RANGE = 500000
  FILES_PER_PAGE = 500
  MAX_RECORDS_COORDINATOR = 4000
  MAX_RECORDS_DATA_MANAGER = 15000 
  MAX_RECORDS_SYSTEM_ADMINISTRATOR = 100000 
  MESSAGE_RECIPIENTS = ['Myself to Review',"Active Transcribers",'Inactive Transcribers','Coordinators','Researchers', 'Managers', 'Coordinators and Managers']
  MINIMUM_NUMBER_OF_FIELDS = 5
  CHURCH_WORD_EXPANSIONS =  {
    'Albans' => 'Alban',
    'Albright\'s' => 'Albright',
    'Andrews' => 'Andrew',
    'Andrew\'s' => 'Andrew',
    'Annes' => 'Anne',
    'Augustines' => 'Augustine',
    'Augustine\'s' => 'Augustine',
    'Barthlomew' => 'Bartholomew',
    'Bartholemew' => 'Bartholomew',
    'Bartholemews' => 'Bartholomew',
    'Batholomew' => 'Bartholomew',
    'Batholomews' => 'Bartholomew',
    'Benedict\'s' => 'Benedict',
    'Benedicts' => 'Benedict',
    'Bololph' => 'Botolph',
    'Boltolph' => 'Botolph',
    'Boltoph' => 'Botolph',
    'Boltophs' => 'Botolph',
    'Botoph' => 'Botolph',
    'Catherines' => 'Catherine',
    'Catherine\'s' => 'Catherine',
    'Chads' => 'Chad',
    'Clements' => 'Clement',
    'Clement\'s' => 'Clement',
    'Cuthberts' => 'Cuthbert',
    'Davids' => 'David',
    'David\'s' => 'David',
    'Dunstans' => 'Dunstan',
    'Edmonds' => 'Edmond',
    'Edmunds' => 'Edmund',
    'Edwards' => 'Edward',
    'Edward\'s' => 'Edward',
    'Elphins' => 'Elphin',
    'Faiths' => 'Faith',
    'Georges' => 'George',
    'George\'s' => 'George',
    'Germans' => 'German',
    'Guthlac\'s' => 'Guthlac',
    'Helens' => 'Helen',
    'Helen\'s' => 'Helen',
    'Johns' => 'John',
    'Julians' => 'Julian',
    'Leonards' => 'Leonard',
    'Loenard\'s' => 'Loenard',
    'Lukes' => 'Luke',
    'Margarets' => 'Margaret',
    'Margaret\'s' => 'Margaret',
    'Marks' => 'Mark',
    'Martins' => 'Martin',
    'Martin\'s' => 'Martin',
    "Marys" => 'Mary',
    'Mary\'s' => 'Mary',
    'Matthews' => 'Matthew',
    'Michaels' => 'Michael',
    'Michael\'s' => 'Michael',
    'Oswalds' => 'Oswald',
    'Pauls'=> 'Paul',
    'Paul\'s' => 'Paul',
    'Pega\'s' => 'Pega',
    'Peters' => 'Peter',
    'Peter\'s' => 'Peter',
    'Philips' => 'Philip',
    'Stevens' => 'Steven',
    'Steven\'s' => 'Steven',

    'Swithen' => 'Swithin',
    'Swithins' => 'Swithin',
    'Swithin\'s' => 'Swithin',
    'Swith1n' => 'Swithin' ,
    'Swithuns' => 'Swithun',
    'Wilfreds' => 'Wilfred',
    'Wilfrid\'s' => 'Wilfrid',
    'Cemetry' => 'Cemetery',
    'Marys' => 'Mary',
    "Mary\'s" => 'Mary',
    "Marys\'" => 'Mary',
    'Nicholas\'' => 'Nicholas'
  }
  COMMON_WORD_EXPANSIONS = {
    'Saints\'' => 'St',
    'Saint\'s' => 'St',
    'Saint' => 'St',
    'SAINT' => 'St',
    'St.' => 'St',
    'st.' => 'St',
    'sT.' => 'St',
    'ST' => 'St',
    'Gt' => 'Great',
    'GT' => 'Great',
    'Gt.' => 'Great',
    'GT.' => 'Great',
    'Lt' => 'Little',
    'LT' => 'Little',
    'Lt.' => 'Little',
    'LT.' => 'Little',
    '&' => "and",
    'NR' => 'near',
    'nr' => 'near',
  }
  CAPITALIZATION_WORD_EXCEPTIONS = [
    "a", "ad" ,"an", "and", "at", "but", "by", "cum", "de", "en" ,"for", "has", "in", "la", "le", "near", "next", "nor", "nr",
    "or", "on", "of", "so",  "the", "to", "under","upon","von", "with", "yet", "y"
  ]
  WORD_START_BRACKET =  /\A\(/
  WORD_SPLITS = {
    "-" => /\-/,
  "&" => /\&/
  }
  HEADER_DETECTION = /[+#][IN][NA][FM][OE].?/
  RECORD_TYPE_TRANSLATION = {
    "BAPTISMS" => RecordType::BAPTISM,
    "MARRIAGES" => RecordType::MARRIAGE,
    "BURIALS" => RecordType::BURIAL,
    "BA" => RecordType::BAPTISM,
    "MA" => RecordType::MARRIAGE,
    "BU" => RecordType::BURIAL
  }
  VALID_RECORD_TYPE = ["BAPTISMS", "MARRIAGES", "BURIALS", "BA","MA", "BU"]
  VALID_CCC_CODE = /\A[CcSs]{3,6}\z/
  HEADER_FLAG = /\A\#\z/
  VALID_CREDIT_CODE = ["CREDIT", "Credit", "credit"]
  ENTRY_ORDER_DEFINITION = { "ba" => {
  :chapman_code=> 1,
  :place_name=> 2,
  :church_name=>3,
  :register_entry_number=> 4,
  :birth_date=> 5,
  :baptism_date=> 6,
  :person_forename=> 7,
  :person_sex=> 8,
  :father_forename=> 9,
  :mother_forename=> 10,
  :father_surname=> 11,
  :mother_surname=> 12,
  :person_abode=>13,
  :father_occupation=> 14,
  :notes=> 15,
  :film=> 16,
  :film_number=> 17
   },   "ma" => {
  :chapman_code=> 1,
  :place_name=> 2,
  :church_name=>3,
  :register_entry_number=> 4,
  :marriage_date=> 5,
  :groom_forename=> 6,
  :groom_surname=> 7,
  :groom_age=> 8,
  :groom_parish=> 9,
  :groom_condition=> 10,
  :groom_occupation=> 11,
  :groom_abode=> 12,
  :bride_forename=> 13,
  :bride_surname=> 14,
  :bride_age=>15,
  :bride_parish=> 16,
  :bride_condition=> 17,
  :bride_occupation=> 18,
  :bride_abode=> 19,
  :groom_father_forename=> 20,
  :groom_father_surname=> 21,
  :groom_father_occupation=> 22,
  :bride_father_forename=> 23,
  :bride_father_surname=> 24,
  :bride_father_occupation=> 25,
  :witness1_forename=> 26,
  :witness1_surname=> 27,
  :witness2_forename=> 28,
  :witness2_surname=> 29,
  :notes=> 30,
  :film=> 31,
  :film_number=> 32
   }, "bu"=> {
  :chapman_code=> 1,
  :place_name=> 2,
  :church_name=>3,
  :register_entry_number=> 4,
  :burial_date=> 5,
  :burial_person_forename=> 6,
  :relationship=> 7,
  :male_relative_forename=> 8,
  :female_relative_forename=> 9,
  :relative_surname=> 10,
  :burial_person_surname=> 11,
  :person_age=> 12,
  :burial_person_abode=> 13,
  :notes=> 14,
  :film=> 15,
  :film_number=> 16
   }}
  VALID_REGISTER_TYPES = /\A[AaBbDdEeMmOoTtPpUu\(][AaBbDdEeHhTtPpTtXxRrWw]?[KkIiTtXxRrWw]?'?[Ss]? ?[\)]?\z/
  CONTAINS_PERIOD = /\./
  ST_PERIOD = /\A[Ss][Tt]\z/
  TEST = {:fieldset => "mine", otherset: "yours"}
end
