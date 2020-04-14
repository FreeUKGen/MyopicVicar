module Freecen
  module Uninhabited
    UNOCCUPIED = 'u'
    BUILDING = 'b'
    MISSING_SCHEDULE = 'n'
    FAMILY_AWAY_VISITING = 'v'

    UNINHABITED_FLAGS = {
      UNOCCUPIED => 'Unoccupied',
      BUILDING => 'Building',
      MISSING_SCHEDULE => 'Missing Schedule',
      FAMILY_AWAY_VISITING => 'Family Away Visiting'
    }

    UNINHABITED_PATTERN = /[ubnv]/
  end

  module Languages
    WELSH = 'W'
    ENGLISH = 'E'
    BOTH = 'B'
    GAELIC = 'G'

    LANGUAGE_FLAGS = {
      WELSH => 'Welsh',
      ENGLISH => 'English',
      BOTH => 'Both',
      GAELIC => 'Gaelic'
    }
  end

  module Sexes
    MALE = 'M'
    FEMALE = 'F'

    SEX_FLAGS = {
      MALE => 'Male',
      FEMALE => 'Female'
    }
  end

  module MaritalStatus
    SINGLE = 'S'
    MARRIED = 'M'
    WIDOWED = 'W'

    MARITAL_STATUS_FLAGS = {
      SINGLE => 'Single',
      MARRIED => 'Married',
      WIDOWED => 'Widowed'
    }
  end

  module SpecialEnumerationDistricts
    CODES = ['None', 'Barracks & Military Quarters', 'HM Ships, at Home', 'Workhouses & Pauper Schools', 'Hospitals (Sick, Convalescent, Incurables)',
             'Lunatic Asylums', 'Prisons', 'Certified Reformatory & Industrial Schools', 'Merchant Vessels & Lighthouses', 'Schools']
  end

  FIELD_NAMES = { "0" => 'Civil Parish', "1" => 'Enumeration District', "2" => 'Folio', "3" => 'Page', "4" => 'Dwelling', "8" => 'Individual' }
  CENSUS_YEARS_ARRAY = ['1841', '1851', '1861', '1871', '1881', '1891', '1901', '1911'].freeze
  CHAPMAN_CODE_ELIMINATIONS = ['England', 'Scotland', 'Wales', 'Ireland', 'Unknown', 'Clwyd', 'Dyfed', 'Gwent', 'Gwynedd', 'Powys', 'Mid Glamorgan',
                               'South Glamorgan', 'West Glamorgan', 'Borders', 'Central', 'Dumfries and Galloway', 'Grampian', 'Highland', 'Lothian',
                               'Orkney Isles', 'Shetland Isles', 'Strathclyde', 'Tayside', 'Western Isles', 'Other Locations'].freeze

  FREECEN1_COLUMN_HEADER_LINE = ['Civil Parish', 'ED', 'Folio', 'Page', 'Schd', 'House', 'Address', 'X', 'Surname', 'Forenames', 'X', 'Rel.', 'C',
                                 'Sex', 'Age', 'X', 'Occupation', 'E', 'X', 'CHP', 'Place of birth', 'X', 'Dis.', 'W', 'Notes'].freeze
  CEN2_TRADITIONAL_COLUMN_HEADER_LINE = [
    'Civil Parish', 'ED', 'Folio', 'Page', 'Schd', 'House', 'Address', 'X', 'Surname', 'Forenames', 'X', 'Rel.', 'C', 'Sex', 'Age', 'X', 'Occupation',
    'E', 'X', 'CHP', 'Place of birth', 'X', 'Dis.', 'W', 'Notes', 'Alt. CHP', 'Alt. POB', 'deleted', 'ecclesiastical', 'address_flag'
  ].freeze
  LOCATION_FIELDS = %w[civil_parish enumeration_district ecclesiastical_parish municipal_borough ward parliamentary_constituency sanitary_district
                       school_board location_flag].freeze

  HOUSEHOLD_FIELDS = %w[folio_number page_number schedule_number uninhabited_flag house_number house_or_street_name address_flag].freeze

  IRE_HOUSEHOLD_FIELDS = %w[folio_number page_number schedule_number uninhabited_flag house_number house_or_street_name rooms_with_windows roof_type
                            address_flag].freeze

  SCT_HOUSEHOLD_FIELDS = %w[folio_number page_number schedule_number uninhabited_flag house_number house_or_street_name rooms_with_windows
                            address_flag].freeze

  INDIVIDUAL_FIELDS = %w[surname forenames name_flag relationship marital_status sex age individual_flag].freeze

  SCT_INDIVIDUAL_FIELDS = %w[surname surname_maiden forenames name_flag relationship marital_status sex age individual_flag].freeze

  ADDITIONAL_INDIVIDUAL_FIELDS = %w[surname forenames name_flag relationship marital_status sex age years_married children_born_alive children_living
                                    children_deceased individual_flag].freeze
  ADDITIONAL_SCT_INDIVIDUAL_FIELDS = %w[surname forenames name_flag relationship marital_status sex age years_married children_born_alive
                                        children_living children_deceased individual_flag].freeze

  OCCUPATION_FIELDS = %w[occupation industry occupation_category at_home occupation_flag].freeze

  BIRTH_FIELDS = %w[verbatim_birth_county verbatim_birth_place nationality birth_county birth_place birth_place_flag].freeze

  ADDITIONAL_FIELDS = %w[disability disability_notes language notes].freeze

  CEN2_1841_FIELD_COLUMN_HEADER_LINE = LOCATION_FIELDS - %w[ecclesiastical_parish ward sanitary_district school_board] + HOUSEHOLD_FIELDS +
    INDIVIDUAL_FIELDS - %w[relationship marital_status] + OCCUPATION_FIELDS - %w[industry occupation_category at_home] + BIRTH_FIELDS -
    %w[verbatim_birth_place nationality birth_place] + %w[notes]

  CEN2_1851_FIELD_COLUMN_HEADER_LINE = LOCATION_FIELDS - %w[ward sanitary_district school_board] + HOUSEHOLD_FIELDS +
    INDIVIDUAL_FIELDS + OCCUPATION_FIELDS - %w[industry occupation_category at_home] + BIRTH_FIELDS +
    ADDITIONAL_FIELDS - %w[disability_notes]

  CEN2_1861_FIELD_COLUMN_HEADER_LINE = LOCATION_FIELDS - %w[sanitary_district school_board] + HOUSEHOLD_FIELDS +
    INDIVIDUAL_FIELDS + OCCUPATION_FIELDS - %w[industry occupation_category at_home] + BIRTH_FIELDS +
    ADDITIONAL_FIELDS - %w[disability_notes]

  CEN2_1871_FIELD_COLUMN_HEADER_LINE = LOCATION_FIELDS - %w[school_board] + HOUSEHOLD_FIELDS +
    INDIVIDUAL_FIELDS + OCCUPATION_FIELDS - %w[industry occupation_category at_home] + BIRTH_FIELDS +
    ADDITIONAL_FIELDS - %w[disability_notes]

  CEN2_1881_FIELD_COLUMN_HEADER_LINE = LOCATION_FIELDS - %w[school_board] + HOUSEHOLD_FIELDS +
    INDIVIDUAL_FIELDS + OCCUPATION_FIELDS - %w[industry occupation_category at_home] + BIRTH_FIELDS +
    ADDITIONAL_FIELDS - %w[disability_notes]

  CEN2_1891_FIELD_COLUMN_HEADER_LINE = LOCATION_FIELDS - %w[school_board] + HOUSEHOLD_FIELDS +
    INDIVIDUAL_FIELDS + OCCUPATION_FIELDS - %w[industry at_home] + BIRTH_FIELDS +
    ADDITIONAL_FIELDS - %w[disability_notes]

  CEN2_1901_FIELD_COLUMN_HEADER_LINE = LOCATION_FIELDS - %w[sanitary_district school_board] + HOUSEHOLD_FIELDS - %w[address_flag] +
    %w[rooms address_flag] + INDIVIDUAL_FIELDS + OCCUPATION_FIELDS - %w[industry] + BIRTH_FIELDS + ADDITIONAL_FIELDS -
    %w[disability_notes]

  CEN2_1911_FIELD_COLUMN_HEADER_LINE = LOCATION_FIELDS - %w[sanitary_district school_board] + HOUSEHOLD_FIELDS - %w[folio_number
    page_number uninhabited_flag address_flag] + %w[rooms address_flag] + ADDITIONAL_INDIVIDUAL_FIELDS - %w[surname_maiden school_children] +
    OCCUPATION_FIELDS + BIRTH_FIELDS + ADDITIONAL_FIELDS

  CEN2_SCT_1841_FIELD_COLUMN_HEADER_LINE = LOCATION_FIELDS - %w[ecclesiastical_parish ward sanitary_district school_board] +
    HOUSEHOLD_FIELDS + SCT_INDIVIDUAL_FIELDS - %w[relationship marital_status] + OCCUPATION_FIELDS - %w[industry occupation_category at_home] +
    BIRTH_FIELDS - %w[verbatim_birth_place nationality birth_county birth_place] + %w[notes]

  CEN2_SCT_1851_FIELD_COLUMN_HEADER_LINE = LOCATION_FIELDS - %w[ward sanitary_district school_board] + HOUSEHOLD_FIELDS +
    SCT_INDIVIDUAL_FIELDS + OCCUPATION_FIELDS - %w[industry occupation_category at_home] + BIRTH_FIELDS +
    ADDITIONAL_FIELDS - %w[disability_notes language]

  CEN2_SCT_1861_FIELD_COLUMN_HEADER_LINE = LOCATION_FIELDS - %w[sanitary_district school_board] + SCT_HOUSEHOLD_FIELDS +
    SCT_INDIVIDUAL_FIELDS - %w[individual_flag] + %w[school_children individual_flag] + OCCUPATION_FIELDS - %w[industry occupation_category at_home] + BIRTH_FIELDS +
    ADDITIONAL_FIELDS - %w[disability_notes]

  CEN2_SCT_1871_FIELD_COLUMN_HEADER_LINE = LOCATION_FIELDS - %w[sanitary_district school_board] + SCT_HOUSEHOLD_FIELDS +
    SCT_INDIVIDUAL_FIELDS + OCCUPATION_FIELDS - %w[industry occupation_category at_home] + BIRTH_FIELDS +
    ADDITIONAL_FIELDS - %w[disability_notes language]

  CEN2_SCT_1881_FIELD_COLUMN_HEADER_LINE = LOCATION_FIELDS - %w[sanitary_district] + SCT_HOUSEHOLD_FIELDS +
    SCT_INDIVIDUAL_FIELDS + OCCUPATION_FIELDS - %w[industry occupation_category at_home] + BIRTH_FIELDS +
    ADDITIONAL_FIELDS - %w[disability_notes]

  CEN2_SCT_1891_FIELD_COLUMN_HEADER_LINE = LOCATION_FIELDS - %w[sanitary_district] + SCT_HOUSEHOLD_FIELDS +
    SCT_INDIVIDUAL_FIELDS + OCCUPATION_FIELDS - %w[industry at_home] + BIRTH_FIELDS +
    ADDITIONAL_FIELDS - %w[disability_notes]

  CEN2_SCT_1901_FIELD_COLUMN_HEADER_LINE = LOCATION_FIELDS - %w[sanitary_district] + SCT_HOUSEHOLD_FIELDS +
    SCT_INDIVIDUAL_FIELDS + OCCUPATION_FIELDS - %w[industry] + BIRTH_FIELDS + ADDITIONAL_FIELDS - %w[disability_notes]

  CEN2_SCT_1911_FIELD_COLUMN_HEADER_LINE = LOCATION_FIELDS - %w[sanitary_district] + SCT_HOUSEHOLD_FIELDS - %w[uninhabited_flag] +
    ADDITIONAL_SCT_INDIVIDUAL_FIELDS + OCCUPATION_FIELDS + BIRTH_FIELDS + ADDITIONAL_FIELDS

  CEN2_IRL_1841_FIELD_COLUMN_HEADER_LINE = LOCATION_FIELDS - %w[ecclesiastical_parish ward sanitary_district school_board] +
    HOUSEHOLD_FIELDS + INDIVIDUAL_FIELDS  - %w[relationship marital_status] + OCCUPATION_FIELDS - %w[industry occupation_category at_home] + BIRTH_FIELDS -
    %w[verbatim_birth_place nationality birth_county birth_place] + %w[notes]

  CEN2_IRL_1851_FIELD_COLUMN_HEADER_LINE = LOCATION_FIELDS - %w[ward sanitary_district school_board] + HOUSEHOLD_FIELDS +
    INDIVIDUAL_FIELDS + OCCUPATION_FIELDS - %w[industry occupation_category at_home] + BIRTH_FIELDS +
    ADDITIONAL_FIELDS - %w[disability_notes language]

  CEN2_IRL_1861_FIELD_COLUMN_HEADER_LINE = LOCATION_FIELDS - %w[sanitary_district school_board] + HOUSEHOLD_FIELDS +
    INDIVIDUAL_FIELDS + OCCUPATION_FIELDS - %w[industry occupation_category at_home] + BIRTH_FIELDS +
    ADDITIONAL_FIELDS - %w[disability_notes]

  CEN2_IRL_1871_FIELD_COLUMN_HEADER_LINE = LOCATION_FIELDS - %w[sanitary_district school_board] + HOUSEHOLD_FIELDS +
    INDIVIDUAL_FIELDS + OCCUPATION_FIELDS - %w[industry occupation_category at_home] + BIRTH_FIELDS +
    ADDITIONAL_FIELDS - %w[disability_notes language]

  CEN2_IRL_1881_FIELD_COLUMN_HEADER_LINE = LOCATION_FIELDS - %w[sanitary_district school_board] + HOUSEHOLD_FIELDS +
    INDIVIDUAL_FIELDS + OCCUPATION_FIELDS - %w[industry occupation_category at_home] + BIRTH_FIELDS +
    ADDITIONAL_FIELDS - %w[disability_notes]

  CEN2_IRL_1891_FIELD_COLUMN_HEADER_LINE = LOCATION_FIELDS - %w[sanitary_district school_board] + HOUSEHOLD_FIELDS +
    INDIVIDUAL_FIELDS + OCCUPATION_FIELDS - %w[industry at_home] + BIRTH_FIELDS +
    ADDITIONAL_FIELDS - %w[disability_notes]

  CEN2_IRL_1901_FIELD_COLUMN_HEADER_LINE = LOCATION_FIELDS - %w[sanitary_district school_board] + IRE_HOUSEHOLD_FIELDS +
    INDIVIDUAL_FIELDS - %w[individual_flag] + %w[religion read_write individual_flag] + OCCUPATION_FIELDS -
    %w[industry] + BIRTH_FIELDS + ADDITIONAL_FIELDS - %w[disability_notes]

  CEN2_IRL_1911_FIELD_COLUMN_HEADER_LINE = LOCATION_FIELDS - %w[sanitary_district school_board] + IRE_HOUSEHOLD_FIELDS - %w[folio_number
  page_number uninhabited_flag] + ADDITIONAL_INDIVIDUAL_FIELDS - %w[individual_flag] + %w[religion read_write individual_flag] +
    OCCUPATION_FIELDS + BIRTH_FIELDS + ADDITIONAL_FIELDS

  LINE2 = ['abcdefghijklmnopqrst', '###a', '####a', '####', '###a', '####a', 'abcdefghijklmnopqrstuvwxyzabcd', 'X', 'abcdefghijklmnopqrstuvwx',
           'abcdefghijklmnopqrstuvwx', 'X', 'abcdef', 'C', 'S', '###a', 'X', 'abcdefghijklmnopqrstuvwxyzabcd', 'E', 'X', 'abc',
           'abcdefghijklmnopqrst', 'X', 'abcdef,W,abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqr', 'd', 'abcdefgh'].freeze

  HEADER_OPTIONS_TRANSLATION = [
    FREECEN1_COLUMN_HEADER_LINE, CEN2_TRADITIONAL_COLUMN_HEADER_LINE, CEN2_1841_FIELD_COLUMN_HEADER_LINE, CEN2_1851_FIELD_COLUMN_HEADER_LINE,
    CEN2_1861_FIELD_COLUMN_HEADER_LINE, CEN2_1871_FIELD_COLUMN_HEADER_LINE, CEN2_1881_FIELD_COLUMN_HEADER_LINE, CEN2_1891_FIELD_COLUMN_HEADER_LINE,
    CEN2_1901_FIELD_COLUMN_HEADER_LINE, CEN2_1911_FIELD_COLUMN_HEADER_LINE,
    CEN2_SCT_1841_FIELD_COLUMN_HEADER_LINE, CEN2_SCT_1851_FIELD_COLUMN_HEADER_LINE, CEN2_SCT_1861_FIELD_COLUMN_HEADER_LINE,
    CEN2_SCT_1871_FIELD_COLUMN_HEADER_LINE, CEN2_SCT_1881_FIELD_COLUMN_HEADER_LINE, CEN2_SCT_1891_FIELD_COLUMN_HEADER_LINE,
    CEN2_SCT_1901_FIELD_COLUMN_HEADER_LINE, CEN2_SCT_1911_FIELD_COLUMN_HEADER_LINE,
    CEN2_IRL_1841_FIELD_COLUMN_HEADER_LINE, CEN2_IRL_1851_FIELD_COLUMN_HEADER_LINE, CEN2_IRL_1861_FIELD_COLUMN_HEADER_LINE,
    CEN2_IRL_1871_FIELD_COLUMN_HEADER_LINE, CEN2_IRL_1881_FIELD_COLUMN_HEADER_LINE, CEN2_IRL_1891_FIELD_COLUMN_HEADER_LINE,
    CEN2_IRL_1901_FIELD_COLUMN_HEADER_LINE, CEN2_IRL_1911_FIELD_COLUMN_HEADER_LINE,
  ].freeze
  HEADER_OPTIONS = %w[Freecen1 Freecen2_traditional 1841 1851 1861 1871 1881 1891 1901 1911  Scotland_1841 Scotland_1851 Scotland_1861 Scotland_1871
    Scotland_1881 Scotland_1891 Scotland_1901 Scotland_1911 Ireland_1841 Ireland_1851 Ireland_1861 Ireland_1871 Ireland_1881 Ireland_1891 Ireland_1901
    Ireland_1911]


  FIELD_NAMES_CONVERSION = {
    'civil parish' => 'civil_parish',
    'ed' => 'enumeration_district',
    'folio' => 'folio_number',
    'page' => 'page_number',
    'schd' => 'schedule_number',
    'house' => 'house_number',
    'address' => 'house_or_street_name',
    'xu' => 'uninhabited_flag',
    'xn' => 'name_flag',
    'rel.' => 'relationship',
    'c' => 'marital_status',
    'sex' => 'sex',
    'age' => 'age',
    'xd' => 'individual_flag',
    'occupation' => 'occupation',
    'e' => 'occupation_category',
    'xo' => 'occupation_flag',
    'chp' => 'verbatim_birth_county',
    'place of birth' => 'verbatim_birth_place',
    'xb' => 'birth_place_flag',
    'dis.' => 'disability',
    'w' => 'language',
    'language' => 'language',
    'notes' => 'notes',
    'deleted' => 'deleted_flag',
    'deleted_flag' => 'deleted_flag',
    'ecclesiastical_parish' => 'ecclesiastical_parish',
    'ecclesiastical' => 'ecclesiastical_parish',
    'at home' => 'at_home',
    'rooms' => 'rooms',
    'birth_county' => 'birth_county',
    'birth_place' => 'birth_place',
    'address_flag' => 'address_flag',
    'civil_parish' => 'civil_parish',
    'enumeration_district' => 'enumeration_district',
    'folio_number' => 'folio_number',
    'page_number' => 'page_number',
    'schedule_number' => 'schedule_number',
    'house_number' => 'house_number',
    'house_or_street_name' => 'house_or_street_name',
    'uninhabited_flag' => 'uninhabited_flag',
    'forenames' => 'forenames',
    'surname' => 'surname',
    'surname_maiden' => 'surname_maiden',
    'location_flag' => 'location_flag',
    'name_flag' => 'name_flag',
    'relationship' => 'relationship',
    'marital_status' => 'marital_status',
    'individual_flag' => 'individual_flag',
    'occupation_category' => 'occupation_category',
    'industry' => 'industry',
    'occupation_flag' => 'occupation_flag',
    'verbatim_birth_county' => 'verbatim_birth_county',
    'verbatim_birth_place' => 'verbatim_birth_place',
    'birth_place_flag' => 'birth_place_flag',
    'disability' => 'disability',
    'municipal_borough' => 'municipal_borough',
    'ward' => 'ward',
    'parliamentary_constituency' => 'parliamentary_constituency',
    'school_board' => 'school_board',
    'school_children' => 'school_children',
    'years_married' => 'years_married',
    'children_born_alive' => 'children_born_alive',
    'children_deceased' => 'children_deceased',
    'children_living' => 'children_living',
    'nationality' => 'nationality',
    'disability_notes' => 'disability_notes',
    'religion' => 'religion',
    'read_write' => 'read_write',
    'sanitary_district' => 'sanitary_district',
    'rooms_with_windows' => 'rooms_with_windows'
  }
end
