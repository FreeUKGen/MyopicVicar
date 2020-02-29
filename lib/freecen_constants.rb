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

  FIELD_NAMES = ['Civil Parish', 'Folio', 'Page', 'Dwelling', 'Individual', 'Error']


  CENSUS_YEARS_ARRAY = ['1841', '1851', '1861', '1871', '1881', '1891']
  CHAPMAN_CODE_ELIMINATIONS = ['England', 'Scotland', 'Wales', 'Ireland', 'Unknown', 'Clwyd', 'Dyfed', 'Gwent', 'Gwynedd', 'Powys', 'Mid Glamorgan',
                               'South Glamorgan', 'West Glamorgan', 'Borders', 'Central', 'Dumfries and Galloway', 'Grampian', 'Highland', 'Lothian',
                               'Orkney Isles', 'Shetland Isles', 'Strathclyde', 'Tayside', 'Western Isles', 'Other Locations']
end
