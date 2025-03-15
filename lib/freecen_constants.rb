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
  UNINHABITED = { 'B' => 'Under Construction', 'U' => 'Unoccupied', 'V' => 'Family Away Visiting', 'N' => 'Missing Schedule' }.freeze

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

  module Listings
    NAMES = {
      'Civ' => 'Civil Parish',
      'Pag' => 'Page',
      'Dwe' => 'Dwelling',
      'Ind' => 'Individual',
      'Err' => 'Error',
      'War' => 'Warning',
      'Inf' => 'Information',
      'Fla' => 'Flag'
    }.freeze
  end

  CENSUS_START_YEAR = "1831"
  CENSUS_END_YEAR = "1931"
  CENSUS_YEARS = (CENSUS_START_YEAR..CENSUS_END_YEAR).step(10).to_a

  module SpecialEnumerationDistricts
    CODES = ['None', 'Barracks & Military Quarters', 'HM Ships, at Home', 'Workhouses & Pauper Schools', 'Hospitals (Sick, Convalescent, Incurables)',
             'Lunatic Asylums', 'Prisons', 'Certified Reformatory & Industrial Schools', 'Merchant Vessels & Lighthouses', 'Schools'].freeze
  end

  CENSUS_YEARS_ARRAY = ['1841', '1851', '1861', '1871', '1881', '1891', '1901', '1911', '1921'].freeze
  CHAPMAN_CODE_ELIMINATIONS = ['England', 'Scotland', 'Wales', 'Ireland', 'Clwyd', 'Dyfed', 'Gwent', 'Gwynedd', 'Powys', 'Mid Glamorgan',
                               'South Glamorgan', 'West Glamorgan', 'Borders', 'Central', 'Dumfries and Galloway', 'Grampian', 'Highland', 'Lothian',
                               'Orkney', 'Shetland', 'Strathclyde', 'Tayside', 'Western'].freeze

  LOCATION = %w[enumeration_district civil_parish petty_sessional_division county_court_district ecclesiastical_parish where_census_taken ward parliamentary_constituency poor_law_union
                       police_district sanitary_district special_water_district scavenging_district special_lighting_district school_board
                       location_flag].freeze

  LOCATION_FOLIO = %w[enumeration_district civil_parish petty_sessional_division county_court_district ecclesiastical_parish where_census_taken ward parliamentary_constituency poor_law_union
                       police_district sanitary_district special_water_district scavenging_district special_lighting_district school_board
                       location_flag folio_number].freeze

  LOCATION_PAGE = %w[enumeration_district civil_parish petty_sessional_division county_court_district ecclesiastical_parish where_census_taken ward parliamentary_constituency poor_law_union
                       police_district sanitary_district special_water_district scavenging_district special_lighting_district school_board
                       location_flag folio_number page_number].freeze

  LOCATION_DWELLING = %w[enumeration_district civil_parish petty_sessional_division county_court_district ecclesiastical_parish where_census_taken ward parliamentary_constituency poor_law_union
                       police_district sanitary_district special_water_district scavenging_district special_lighting_district school_board
                       location_flag folio_number page_number schedule_number uninhabited_flag house_number house_or_street_name address_flag
                       walls roof_type rooms rooms_with_windows class_of_house rooms_with_windows].freeze

  HOUSEHOLD = %w[folio_number page_number schedule_number uninhabited_flag house_number house_or_street_name address_flag].freeze

  IRE_HOUSEHOLD = %w[schedule_number uninhabited_flag house_number house_or_street_name walls roof_type rooms
                            rooms_with_windows class_of_house address_flag].freeze

  SCT_HOUSEHOLD = %w[folio_number page_number schedule_number uninhabited_flag house_number house_or_street_name rooms_with_windows
                            address_flag].freeze

  INDIVIDUAL = %w[surname forenames name_flag relationship marital_status sex age individual_flag].freeze

  INDIVIDUAL_1921 =  %w[surname forenames name_flag relationship age sex marital_status individual_flag].freeze

  EXTRA_INDIVIDUAL = %w[surname forenames name_flag relationship marital_status sex age years_married children_born_alive children_living
                                    children_deceased individual_flag].freeze

  OCCUPATION = %w[occupation industry occupation_category at_home occupation_flag].freeze

  OCCUPATION_1921 = %w[education occupation employment place_of_work occupation_flag].freeze

  BIRTH = %w[verbatim_birth_county verbatim_birth_place nationality birth_county birth_place birth_place_flag].freeze

  FINAL = %w[disability disability_notes children_under_sixteen language notes].freeze

  VLD_FIELDS = %w[age birth_county birth_place civil_parish disability ecclesiastical_parish enumeration_district folio_number
                  forenames house_number house_or_street_name language marital_status notes occupation page_number relationship
                  schedule_number sex surname uninhabited_flag verbatim_birth_county verbatim_birth_place].freeze

  FREECEN1_HEADER = ['Civil Parish', 'ED', 'Folio', 'Page', 'Schd', 'House', 'Address', 'X', 'Surname', 'Forenames', 'X', 'Rel.', 'C',
                     'Sex', 'Age', 'X', 'Occupation', 'E', 'X', 'CHP', 'Place of birth', 'X', 'Dis.', 'W', 'Notes'].freeze
  CEN2_TRADITIONAL = [
    'Civil Parish', 'ED', 'Folio', 'Page', 'Schd', 'House', 'Address', 'X', 'Surname', 'Forenames', 'X', 'Rel.', 'C', 'Sex', 'Age', 'X', 'Occupation',
    'E', 'X', 'CHP', 'Place of birth', 'X', 'Dis.', 'W', 'Notes', 'Alt. CHP', 'Alt. POB', 'deleted', 'ecclesiastical', 'address_flag'
  ].freeze

  CEN2_1841 = LOCATION - %w[petty_sessional_division county_court_district ecclesiastical_parish ward poor_law_union police_district sanitary_district special_water_district scavenging_district
              special_lighting_district school_board] + HOUSEHOLD + INDIVIDUAL - %w[relationship marital_status] + OCCUPATION - %w[industry
              occupation_category at_home] + BIRTH - %w[verbatim_birth_place nationality birth_place] + %w[notes]

  CEN2_1851 = LOCATION - %w[petty_sessional_division county_court_district ward poor_law_union police_district sanitary_district special_water_district scavenging_district special_lighting_district
              school_board] + HOUSEHOLD + INDIVIDUAL + OCCUPATION - %w[industry occupation_category at_home] + BIRTH + FINAL - %w[disability_notes children_under_sixteen language]

  CEN2_1861 = LOCATION - %w[petty_sessional_division county_court_district poor_law_union police_district sanitary_district special_water_district scavenging_district special_lighting_district
              school_board] + HOUSEHOLD + INDIVIDUAL + OCCUPATION - %w[industry occupation_category at_home] + BIRTH + FINAL - %w[disability_notes children_under_sixteen language]

  CEN2_1871 = LOCATION - %w[petty_sessional_division county_court_district poor_law_union police_district special_water_district scavenging_district special_lighting_district school_board
              school_board] + HOUSEHOLD + INDIVIDUAL + OCCUPATION - %w[industry occupation_category at_home] + BIRTH + FINAL - %w[disability_notes children_under_sixteen language]

  CEN2_1881 = LOCATION - %w[petty_sessional_division county_court_district poor_law_union police_district special_water_district scavenging_district special_lighting_district school_board
              school_board] + HOUSEHOLD + INDIVIDUAL + OCCUPATION - %w[industry occupation_category at_home] + BIRTH + FINAL - %w[disability_notes children_under_sixteen language]

  CEN2_1891 = LOCATION - %w[petty_sessional_division county_court_district poor_law_union police_district special_water_district scavenging_district special_lighting_district school_board] +
    HOUSEHOLD - %w[address_flag] + %w[rooms address_flag] + INDIVIDUAL + OCCUPATION - %w[industry at_home] + BIRTH + FINAL - %w[disability_notes children_under_sixteen]

  CEN2_1901 = LOCATION - %w[petty_sessional_division county_court_district poor_law_union police_district sanitary_district special_water_district scavenging_district special_lighting_district
              school_board] + HOUSEHOLD - %w[address_flag] + %w[rooms address_flag] + INDIVIDUAL + OCCUPATION - %w[industry] + BIRTH +
    FINAL - %w[disability_notes children_under_sixteen]

  CEN2_1911 = LOCATION - %w[petty_sessional_division county_court_district poor_law_union police_district sanitary_district special_water_district scavenging_district special_lighting_district
              school_board] + HOUSEHOLD - %w[folio_number page_number uninhabited_flag address_flag] + %w[rooms address_flag] + EXTRA_INDIVIDUAL -
    %w[surname_maiden school_children] + OCCUPATION + BIRTH + FINAL - %w(children_under_sixteen)

  CEN2_1921 = LOCATION - %w[poor_law_union police_district sanitary_district special_water_district scavenging_district special_lighting_district
              school_board] + HOUSEHOLD - %w[folio_number page_number address_flag] + %w[rooms address_flag] + INDIVIDUAL_1921 +
    BIRTH + OCCUPATION_1921 + FINAL - %w[disability disability_notes]

  CEN2_CHANNEL_ISLANDS_1911 = CEN2_1911 - FINAL - %w[poor_law_union police_district sanitary_district special_water_district scavenging_district
              special_lighting_district school_board] - %w[birth_place_flag] + %w[father_place_of_birth birth_place_flag] + FINAL - %w[children_under_sixteen language]

  CEN2_SCT_1841 = LOCATION - %w[ward poor_law_union police_district sanitary_district special_water_district scavenging_district special_lighting_district
                school_board] + HOUSEHOLD + INDIVIDUAL + OCCUPATION - %w[industry occupation_category at_home] + BIRTH + FINAL - %w[children_under_sixteen disability_notes language] - %w[nationality]

  CEN2_SCT_1851 = LOCATION - %w[ward poor_law_union police_district sanitary_district special_water_district scavenging_district special_lighting_district
                  school_board] + HOUSEHOLD + INDIVIDUAL + OCCUPATION - %w[industry occupation_category at_home] + BIRTH + FINAL - %w[children_under_sixteen disability_notes language]

  CEN2_SCT_1861 = LOCATION - %w[poor_law_union police_district sanitary_district special_water_district scavenging_district
                  special_lighting_district school_board] + SCT_HOUSEHOLD + INDIVIDUAL - %w[individual_flag] + %w[school_children individual_flag] +
    OCCUPATION - %w[industry occupation_category at_home] + BIRTH + FINAL - %w[children_under_sixteen disability_notes language]

  CEN2_SCT_1871 = LOCATION - %w[poor_law_union sanitary_district special_water_district scavenging_district special_lighting_district
    school_board] + SCT_HOUSEHOLD + INDIVIDUAL - %w[individual_flag] + %w[school_children individual_flag] + OCCUPATION - %w[industry occupation_category at_home]+
    BIRTH + FINAL - %w[children_under_sixteen disability_notes language]

  CEN2_SCT_1881 = LOCATION - %w[poor_law_union sanitary_district special_water_district scavenging_district special_lighting_district] +
    SCT_HOUSEHOLD + INDIVIDUAL + OCCUPATION - %w[industry occupation_category at_home] + BIRTH + FINAL - %w[children_under_sixteen disability_notes]

  CEN2_SCT_1891 = LOCATION - %w[poor_law_union police_district sanitary_district special_water_district scavenging_district
    special_lighting_district school_board] + SCT_HOUSEHOLD - %w[rooms_with_windows] + INDIVIDUAL + OCCUPATION - %w[industry occupation_category at_home] +
    BIRTH + FINAL - %w[children_under_sixteen disability_notes]

  CEN2_SCT_1901 = LOCATION - %w[poor_law_union sanitary_district special_water_district scavenging_district special_lighting_district] +
    SCT_HOUSEHOLD + INDIVIDUAL + OCCUPATION - %w[industry] + BIRTH + FINAL - %w[children_under_sixteen disability_notes]

  CEN2_SCT_1911 = LOCATION - %w[poor_law_union police_district] + SCT_HOUSEHOLD + EXTRA_INDIVIDUAL - %w[children_deceased] + OCCUPATION + BIRTH +
    FINAL - %w[children_under_sixteen disability_notes]

  CEN2_IRL_1901 = LOCATION - %w[enumeration_district ecclesiastical_parish ward sanitary_district special_water_district scavenging_district
                                  special_lighting_district school_board] + IRE_HOUSEHOLD + INDIVIDUAL - %w[individual_flag] + %w[religion read_write individual_flag] +
    OCCUPATION - %w[industry occupation_category at_home] + BIRTH - %w[nationality] + FINAL - %w[children_under_sixteen disability_notes]

  CEN2_IRL_1911 = LOCATION - %w[enumeration_district ecclesiastical_parish ward sanitary_district special_water_district scavenging_district
    special_lighting_district school_board] + IRE_HOUSEHOLD + EXTRA_INDIVIDUAL - %w[children_deceased children_under_sixteen education individual_flag] + %w[religion
                              read_write individual_flag] + OCCUPATION - %w[industry occupation_category at_home] + BIRTH - %w[nationality] + FINAL - %w[children_under_sixteen disability_notes]

  LINE2 = ['abcdefghijklmnopqrst', '###a', '####a', '####', '###a', '####a', 'abcdefghijklmnopqrstuvwxyzabcd', 'X', 'abcdefghijklmnopqrstuvwx',
           'abcdefghijklmnopqrstuvwx', 'X', 'abcdef', 'C', 'S', '###a', 'X', 'abcdefghijklmnopqrstuvwxyzabcd', 'E', 'X', 'abc',
           'abcdefghijklmnopqrst', 'X', 'abcdef,W,abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqr', 'd', 'abcdefgh'].freeze

  HEADER_OPTIONS_TRANSLATION = [
    CEN2_1841, CEN2_1851,
    CEN2_1861, CEN2_1871, CEN2_1881, CEN2_1891,
    CEN2_1901, CEN2_1911, CEN2_1921,
    CEN2_CHANNEL_ISLANDS_1911,
    CEN2_SCT_1841, CEN2_SCT_1851, CEN2_SCT_1861,
    CEN2_SCT_1871, CEN2_SCT_1881, CEN2_SCT_1891,
    CEN2_SCT_1901, CEN2_SCT_1911,
    CEN2_IRL_1901, CEN2_IRL_1911
  ].freeze

  HEADER_OPTIONS = %w[1841 1851 1861 1871 1881 1891 1901 1911 1921 Channel_Islands_1911 Scotland_1841 Scotland_1851 Scotland_1861 Scotland_1871
                        Scotland_1881 Scotland_1891 Scotland_1901 Scotland_1911 Ireland_1901 Ireland_1911].freeze

  UNNEEDED_COUNTIES = [
    'Central', 'Clwyd', 'Dumfries and Galloway', 'Dyfed', 'Grampian', 'Gwent', 'Gwynedd', 'Highland', 'London (City)',
    'Lothian', 'Mid Glamorgan', 'Military', 'Orkney', 'Other Locations', 'Out of County', 'Powys',
    'Shetland', 'South Glamorgan', 'Strathclyde', 'Tayside', 'Unknown', 'West Glamorgan', 'Western Isles', 'Yorkshire', 'England', 'Scotland',
    'Ireland', 'Wales'
  ].freeze

  OCCUPATIONAL_CATEGORY_1891 = { 'E' => 'Employee', 'R' => 'Employer', 'N' => 'Neither', 'e' => 'Employee', 'r' => 'Employer', 'n' => 'Neither'}.freeze

  OCCUPATIONAL_CATEGORY_1901 = { 'e' => 'Worker', 'r' => 'Employer', 'n' => 'Own Account', 'E' => 'Worker', 'R' => 'Employer', 'N' => 'Own Account'}.freeze

  LANGUAGE = { 'E' => 'English', 'G' => ' Gaelic', 'GE' => 'Gaelic / English', 'I' => 'Irish', 'IE' => 'Irish / English', 'M' => 'Manx',
               'ME' => 'Manx / English', 'W' => 'Welsh', 'WE' => 'Welsh / English', 'B' => 'Welsh / English' }.freeze

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
    'rel' => 'relationship',
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
    'dis' => 'disability',
    'alt. chp' => 'birth_county',
    'alt. pob' => 'birth_place',
    'w' => 'language',
    'l' => 'language',
    'language' => 'language',
    'notes' => 'notes',
    'address_flag' => 'address_flag',
    'at home' => 'at_home',
    'at_home' => 'at_home',
    'birth_county' => 'birth_county',
    'birth_place' => 'birth_place',
    'birth_place_flag' => 'birth_place_flag',
    'children_born_alive' => 'children_born_alive',
    'children_deceased' => 'children_deceased',
    'children_living' => 'children_living',
    'children_under_sixteen' => 'children_under_sixteen',
    'civil_parish' => 'civil_parish',
    'class_of_house' => 'class_of_house',
    'county_court_district' => 'county_court_district',
    'deleted' => 'deleted_flag',
    'deleted_flag' => 'deleted_flag',
    'disability' => 'disability',
    'disability_notes' => 'disability_notes',
    'ecclesiastical' => 'ecclesiastical_parish',
    'ecclesiastical_parish' => 'ecclesiastical_parish',
    'education' => 'education',
    'employment' => 'employment',
    'enumeration_district' => 'enumeration_district',
    'father_place_of_birth' => 'father_place_of_birth',
    'folio_number' => 'folio_number',
    'forenames' => 'forenames',
    'house_number' => 'house_number',
    'house_or_street_name' => 'house_or_street_name',
    'individual_flag' => 'individual_flag',
    'industry' => 'industry',
    'location_flag' => 'location_flag',
    'marital_status' => 'marital_status',
    'name_flag' => 'name_flag',
    'nationality' => 'nationality',
    'occupation_category' => 'occupation_category',
    'occupation_flag' => 'occupation_flag',
    'page_number' => 'page_number',
    'parliamentary_constituency' => 'parliamentary_constituency',
    'petty_sessional_division' => 'petty_sessional_division',
    'place_of_work' => 'place_of_work',
    'read_write' => 'read_write',
    'relationship' => 'relationship',
    'religion' => 'religion',
    'roof_type' => 'roof_type',
    'rooms' => 'rooms',
    'rooms_with_windows' => 'rooms_with_windows',
    'sanitary_district' => 'sanitary_district',
    'schedule_number' => 'schedule_number',
    'school_board' => 'school_board',
    'school_children' => 'school_children',
    'surname' => 'surname',
    'surname_maiden' => 'surname_maiden',
    'uninhabited_flag' => 'uninhabited_flag',
    'verbatim_birth_county' => 'verbatim_birth_county',
    'verbatim_birth_place' => 'verbatim_birth_place',
    'walls' => 'walls',
    'ward' => 'ward',
    'where_census_taken' => 'where_census_taken',
    'years_married' => 'years_married',
    'record_valid' => 'record_valid'
  }
end
