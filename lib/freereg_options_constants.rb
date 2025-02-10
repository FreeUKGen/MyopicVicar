module FreeregOptionsConstants
  require 'record_type'

  ADDITIONAL_BAPTISM_FIELDS = ['confirmation_date', 'received_into_church_date', 'person_surname', 'person_title', 'person_age', 'person_condition',
                               'person_status', 'person_occupation', 'person_place_birth', 'person_county_birth', 'person_relationship', 'father_title', 'father_abode',
                               'father_place', 'father_county', 'mother_title', 'mother_abode', 'mother_condition_prior_to_marriage', 'mother_place_prior_to_marriage',
                               'mother_county_prior_to_marriage', 'mother_occupation', 'private_baptism', 'witness1_forename', 'witness1_surname', 'witness2_forename', 'witness2_surname',
                               'witness3_forename', 'witness3_surname', 'witness4_forename', 'witness4_surname', 'witness5_forename', 'witness5_surname', 'witness6_forename',
                               'witness6_surname', 'witness7_forename', 'witness7_surname', 'witness8_forename', 'witness8_surname'];

  ADDITIONAL_BURIAL_FIELDS = ['death_date', 'burial_person_title', 'male_relative_title', 'female_relative_surname', 'female_relative_title',
                              'cause_of_death', 'burial_location_information', 'place_of_death', 'memorial_information'];

  ADDITIONAL_MARRIAGE_FIELDS = ['contract_date', 'bride_title', 'bride_marked', 'bride_father_title', 'bride_mother_forename',
                                'bride_mother_surname', 'bride_mother_title', 'bride_mother_occupation', 'groom_title', 'groom_marked', 'groom_father_title',
                                'groom_mother_forename', 'groom_mother_surname', 'groom_mother_title', 'groom_mother_occupation', 'marriage_by_licence',
                                'witness3_forename', 'witness3_surname', 'witness4_forename', 'witness4_surname', 'witness5_forename', 'witness5_surname',
                                'witness6_forename', 'witness6_surname', 'witness7_forename', 'witness7_surname', 'witness8_forename', 'witness8_surname'];

  ADDITIONAL_COMMON_FIELDS = ['notes_from_transcriber', 'image_file_name'];

  ALPHABET = ['A-C', 'D-F', 'G-I', 'J-L', 'M-N', 'O-Q', 'R-T', 'U-Z'];
  ALPHABET_SELECTION_LIST = ['CAM', 'CON', 'DUR', 'ESS', 'GLA', 'KEN', 'LAN', 'LIN', 'MDX', 'NBL', 'NFK', 'NTH', 'NTT', 'SOM', 'SRY', 'STS', 'WRY'];
  ALPHABETS = [
    ['A-Z'], ['A-L', 'M-Z'], ['A-I', 'J-O', 'P-Z'], ['A-F', 'G-L', 'M-Q', 'R-Z'], ['A-D', 'E-I', 'J-M', 'N-R', 'P-Z'], ['A-D', 'E-H', 'I-L', 'M-O', 'P-S', 'T-Z'],
    ['A-D', 'E-G', 'H-J', 'K-M', 'N-P', 'Q-S', 'T-Z'], ['A-C', 'D-F', 'G-I', 'J-L', 'M-N', 'O-Q', 'R-T', 'U-Z'],
    ['A-B', 'C-D', 'E-F', 'G-H', 'I-J', 'K-L', 'M-N', 'O-P', 'Q-R', 'S-T', 'U-V', 'W-Z'],
    ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q-R', 'S', 'T', 'U-V', 'W-X', 'Y-Z']
  ];

  CAPITALIZATION_WORD_EXCEPTIONS = ['a', 'ad', 'an', 'and', 'at', 'but', 'by', 'cum', 'de', 'en', 'for', 'has', 'in', 'la', 'le', 'near', 'next', 'nor', 'nr',
                                    'or', 'on', 'of', 'so', 'the', 'to', 'under', 'upon', 'von', 'with', 'yet', 'y'];

  CHAPMAN_CODE_ELIMINATIONS = ['England', 'Scotland', 'Wales', 'Ireland', 'Unknown', 'Clwyd', 'Dyfed', 'Gwent', 'Gwynedd', 'Powys', 'Mid Glamorgan',
                               'South Glamorgan', 'West Glamorgan', 'Borders', 'Central', 'Dumfries and Galloway', 'Grampian', 'Highland', 'Lothian',
                               'Orkney Isles', 'Shetland Isles', 'Strathclyde', 'Tayside', 'Western Isles', 'England and Wales Shipping',
                               'Out of County', 'Overseas British', 'Overseas Foreign', 'Scottish Shipping', 'Military', 'Royal Navy Ships',
                               'Special'];
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
    'Marys' => 'Mary',
    'Mary\'s' => 'Mary',
    'Matthews' => 'Matthew',
    'Michaels' => 'Michael',
    'Michael\'s' => 'Michael',
    'Oswalds' => 'Oswald',
    'Pauls' => 'Paul',
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
    #    'Marys' => 'Mary',   #duplicate key (Marys is already included above)
    #    'Mary\'s' => 'Mary', #duplicate key (Mary\'s is already included above)
    'Marys\'' => 'Mary',
  'Nicholas\'' => 'Nicholas' };

  COMMON_WORD_EXPANSIONS = {
    'Saints\'' => 'St',
    'Saint\'s' => 'St',
    'Saint' => 'St',
    'SAINT' => 'St',
    'St.' => 'St',
    'st.' => 'St',
    'sT.' => 'St',
    'ST' => 'St',
    'ST.' => 'St',
    'Gt' => 'Great',
    'GT' => 'Great',
    'Gt.' => 'Great',
    'GT.' => 'Great',
    'Lt' => 'Little',
    'LT' => 'Little',
    'Lt.' => 'Little',
    'LT.' => 'Little',
    '&' => 'and',
    'NR' => 'near',
    'nr' => 'near'
  };

  COMMUNICATION_TYPES = {
    'Communication' => 'Personal communication',
    'Message' => 'General message',
    'Syndicate' => 'Syndicate message',
    'Feedback' => 'Feedback report',
    'Contact' => 'Research contact'
  };

  COMMUNICATION_ROLES = ['contacts_coordinator', 'county_coordinator', 'country_coordinator', 'data_manager', 'documentation_coordinator',
                         'engagement_coordinator', 'executive_director', 'genealogy_coordinator', 'general_communication_coordinator',
                         'project_manager', 'publicity_coordinator', 'system_administrator', 'syndicate_coordinator',
                         'website_coordinator', 'volunteer_coordinator'];

  CONFIRM_EMAIL_ADDRESS = 120;

  CONTAINS_PERIOD = /\./;

  DATERANGE_MINIMUM = 1530;

  END_FIELDS = ['transcribed_by', 'credit', 'file_line_number', 'film', 'film_number', 'line_id', 'processed_date'];

  ENTRY_ORDER_DEFINITION = { 'ba' => {
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
                             },
                             'ma' => {
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
                               :notes => 30,
                               :film => 31,
                               :film_number => 32
                             },
                             'bu' => {
                               :chapman_code => 1,
                               :place_name => 2,
                               :church_name =>3,
                               :register_entry_number => 4,
                               :burial_date => 5,
                               :burial_person_forename => 6,
                               :relationship => 7,
                               :male_relative_forename => 8,
                               :female_relative_forename => 9,
                               :relative_surname => 10,
                               :burial_person_surname => 11,
                               :person_age => 12,
                               :burial_person_abode => 13,
                               :notes => 14,
                               :film => 15,
                               :film_number => 16
                             }
                             };

  EXTENDED_BAPTISM_LAYOUT = ['register_entry_number', 'birth_date', 'baptism_date', 'confirmation_date', 'received_into_church_date',
                             'person_forename', 'person_surname', 'person_title', 'person_age', 'person_relationship', 'person_sex', 'person_abode', 'person_condition',
                             'person_status', 'person_occupation', 'person_place_birth', 'person_county_birth', 'father_forename', 'father_surname', 'father_title',
                             'father_abode', 'father_occupation', 'father_place', 'father_county', 'mother_forename', 'mother_surname', 'mother_title', 'mother_abode',
                             'mother_condition_prior_to_marriage', 'mother_place_prior_to_marriage', 'mother_county_prior_to_marriage', 'mother_occupation',
                             'private_baptism', 'witness'];

  EXTENDED_BURIAL_LAYOUT = ['register_entry_number', 'burial_date', 'death_date', 'burial_person_forename',
                            'burial_person_surname', 'burial_person_title', 'relationship','person_occupation', 'consecrated_ground', 'male_relative_forename', 'relative_surname',
                            'male_relative_title', 'female_relative_forename', 'female_relative_surname', 'female_relative_title', 'person_age',
                            'burial_person_abode', 'cause_of_death', 'burial_location_information', 'place_of_death', 'memorial_information',
                            'notes', 'notes_from_transcriber', 'film', 'film_number', 'image_file_name'];

  EXTENDED_MARRIAGE_LAYOUT = ['register_entry_number', 'marriage_date', 'contract_date', 'marriage_by_licence', 'groom_forename', 'groom_surname', 'groom_title', 'groom_age',
                              'groom_parish', 'groom_condition', 'groom_occupation', 'groom_abode', 'groom_marked', 'groom_father_forename', 'groom_father_surname', 'groom_father_occupation',
                              'groom_mother_forename', 'groom_mother_surname', 'groom_mother_title', 'groom_mother_occupation', 'bride_forename', 'bride_surname', 'bride_title', 'bride_age',
                              'bride_parish', 'bride_condition', 'bride_occupation', 'bride_abode', 'bride_marked', 'bride_father_forename', 'bride_father_surname', 'bride_father_occupation',
                              'bride_father_title', 'bride_mother_forename', 'bride_mother_surname', 'bride_mother_title', 'bride_mother_occupation', 'witness'];

  FILES_PER_PAGE = 250;

  FORCE_SEARCH_RECORD_RECREATE = ['baptism_date', 'birth_date', 'bride_father_forename', 'bride_father_surname', 'bride_forename', 'bride_surname', 'burial_date',
                                  'burial_person_forename', 'burial_person_surname', 'father_forename', 'father_surname', 'female_relative_forename', 'groom_father_forename',
                                  'groom_father_surname', 'groom_forename', 'groom_surname', 'male_relative_forename', 'marriage_date', 'mother_forename', 'mother_surname',
                                  'person_forename', 'relative_surname', 'witness1_forename', 'witness1_surname', 'witness2_forename', 'witness2_surname'];

  HEADER_DETECTION = /[+#][IN][NA][FM][OE].?/;

  HEADER_FLAG = /\A\#\z/;

  ISSUES = ['Data Question', 'Website Problem', 'Volunteering Question', 'Genealogical Question', 'Enhancement Suggestion', 'Thank-you' , 'General Comment'];

  LOCATION_FIELDS = ['county', 'place', 'church_name', 'register_type'];

  MARKED_OPTIONS = ['y', 'yes', 'marked', 'true'];

  MARRIAGE_BY_LICENCE_OPTIONS = ['y', 'yes', 'licence', 'by licence', 'by_licence', 'marriage_by_licence', 'true'];

  MAXIMUM_NUMBER_OF_RESULTS = 500;

  MAXIMUM_NUMBER_OF_SCANS = 500;

  MAXIMUM_WINESSES = 8;

  MAX_RECORDS_COORDINATOR = 4000;

  MAX_RECORDS_DATA_MANAGER = 15000;

  MAX_RECORDS_SYSTEM_ADMINISTRATOR = 100000;

  MESSAGE_RECIPIENTS = ['Myself to Review', 'Active Transcribers', 'Inactive Transcribers', 'Coordinators', 'Researchers', 'Managers', 'Coordinators and Managers'];

  MINIMUM_NUMBER_OF_FIELDS = 3;

  ORIGINAL_BAPTISM_FIELDS = ['register_entry_number', 'birth_date', 'baptism_date', 'person_forename', 'person_sex', 'father_forename', 'mother_forename', 'father_surname', 'mother_surname',
                             'person_abode', 'father_occupation'];

  ORIGINAL_BURIAL_FIELDS = ['register_entry_number', 'burial_date', 'burial_person_forename', 'relationship', 'male_relative_forename', 'female_relative_forename', 'relative_surname',
                            'burial_person_surname', 'person_age','person_occupation', 'consecrated_ground', 'burial_parish','burial_person_abode'];

  ORIGINAL_COMMON_FIELDS = ['notes', 'film', 'film_number', 'suffix'];

  ORIGINAL_MARRIAGE_FIELDS = ['register_entry_number', 'marriage_date', 'groom_forename', 'groom_surname', 'groom_age', 'groom_parish', 'groom_condition', 'groom_occupation', 'groom_abode',
                              'bride_forename', 'bride_surname', 'bride_age', 'bride_parish', 'bride_condition', 'bride_occupation', 'bride_abode', 'groom_father_forename',
                              'groom_father_surname', 'groom_father_occupation', 'bride_father_forename', 'bride_father_surname', 'bride_father_occupation', 'witness1_forename',
                              'witness1_surname', 'witness2_forename', 'witness2_surname'];

  ORIGINAL_MARRIAGE_LAYOUT = ['register_entry_number', 'marriage_date', 'groom_forename', 'groom_surname', 'groom_age', 'groom_parish', 'groom_condition', 'groom_occupation', 'groom_abode',
                              'bride_forename', 'bride_surname', 'bride_age', 'bride_parish', 'bride_condition', 'bride_occupation', 'bride_abode', 'groom_father_forename',
                              'groom_father_surname', 'groom_father_occupation', 'bride_father_forename', 'bride_father_surname', 'bride_father_occupation', 'witness'];

  PRIVATE_BAPTISM_OPTIONS = ['y', 'yes', 'private', 'true', 'private baptism',  'private_baptism'];

  RECORDS_PER_RANGE = 100000;

  RECORD_TYPE_TRANSLATION = {
    'BAPTISMS' => RecordType::BAPTISM,
    'MARRIAGES' => RecordType::MARRIAGE,
    'BURIALS' => RecordType::BURIAL,
    'BA' => RecordType::BAPTISM,
    'MA' => RecordType::MARRIAGE,
  'BU' => RecordType::BURIAL };

  REGISTER_TYPE_ORDER = ['Parish Register', "Archdeacon's Transcript", "Bishop's Transcript", 'Other Register', 'Extract of a Register',
                         'Other Document', "Phillimore's Transcript", "Dwelly's Transcript", 'Other Transcript', 'Memorial Inscription', 'Unknown', 'Unspecified'];

  SOURCE_NAME = ['Image Server', 'Other Server1', 'Other Server2', 'Other Server3'];

  ST_PERIOD = /\A[Ss][Tt]\z/;

  TEST = {:fieldset => 'mine', otherset: 'yours'};

  USERID_DETAILS_MYOWN_DISPLAY = [ 'person_surname', 'person_forename', 'email_address', 'alternate_email_address', 'address', 'telephone_number',
                                   'syndicate', 'skill_level' , 'fiche_reader' , 'person_role', 'sign_up_date', 'new_transcription_agreement',
                                   'no_processing_messages', 'do_not_acknowledge_me', 'acknowledge_with_pseudo_name', 'pseudo_name', 'last_upload', 'number_of_files', 'active',
                                   'disabled_date', 'disabled_reason_standard', 'disabled_reason', 'email_address_valid', 'email_address_last_confirmned', 'reason_for_invalidating',
                                   'email_address_validity_change_message'  ];


  VALID_RECORD_TYPE = ['BAPTISMS', 'MARRIAGES', 'BURIALS', 'BA', 'MA', 'BU'];
  VALID_CCC_CODE = /\A[CcSs]{3,6}\z/;

  VALID_CREDIT_CODE = ['CREDIT', 'Credit', 'credit'];

  VALID_REGISTER_TYPES = /\A[AaBbDdEeMmOoTtPpUu\(][AaBbDdEeHhTtPpTtXxRrWw]?[KkIiTtXxRrWw]?'?[Ss]? ?[\)]?\z/;

  WORD_START_BRACKET =  /\A\(/;

  WORD_SPLITS = {
    '-' => /\-/,
  '&' => /\&/   };

  FLEXIBLE_CSV_FORMAT_BAPTISM = LOCATION_FIELDS + ORIGINAL_BAPTISM_FIELDS + ADDITIONAL_BAPTISM_FIELDS + ORIGINAL_COMMON_FIELDS + ADDITIONAL_COMMON_FIELDS;

  FLEXIBLE_CSV_FORMAT_BURIAL = LOCATION_FIELDS + ORIGINAL_BURIAL_FIELDS + ADDITIONAL_BURIAL_FIELDS + ORIGINAL_COMMON_FIELDS + ADDITIONAL_COMMON_FIELDS;

  FLEXIBLE_CSV_FORMAT_MARRIAGE = LOCATION_FIELDS + ORIGINAL_MARRIAGE_FIELDS + ADDITIONAL_MARRIAGE_FIELDS + ORIGINAL_COMMON_FIELDS + ADDITIONAL_COMMON_FIELDS;

  ORIGINAL_CSV_FORMAT_BAPTISM = LOCATION_FIELDS + ORIGINAL_BAPTISM_FIELDS + ORIGINAL_COMMON_FIELDS;

  ORIGINAL_CSV_FORMAT_BURIAL = LOCATION_FIELDS + ORIGINAL_BURIAL_FIELDS + ORIGINAL_COMMON_FIELDS;

  ORIGINAL_CSV_FORMAT_MARRIAGE = LOCATION_FIELDS + ORIGINAL_MARRIAGE_FIELDS + ORIGINAL_COMMON_FIELDS;

end
