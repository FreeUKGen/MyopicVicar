module Freecen
  module Unoccupied
    UNOCCUPIED = 'u'
    BUILDING = 'b'
    MISSING_SCHEDULE = 'n'
    FAMILY_AWAY_VISITING = 'v'
    
    UNOCCUPIED_FLAGS = {
      UNNOCCUPIED => 'Unoccupied',
      BUILDING => 'Building',
      MISSING_SCHEDULE => 'Missing Schedule',
      FAMILY_AWAY_VISITING => 'Family Away Visiting'
    }
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
end