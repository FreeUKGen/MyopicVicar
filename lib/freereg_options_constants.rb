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
     ["A-Z"], ["A-L","M-Z"], ["A-I","J-O", "P-Z"], ["A-F", "G-L", "M-Q", "R-Z"],["A-D","F-I","L-O","P-Z"],["A-D","F-H","I-L","M-O","P-S","T-Z"],
     ["A-D","E-G","H-J","K-M","N-P","Q-S","T-Z"],["A-C","D-F","G-I","J-L","M-N","O-Q","R-T","U-Z"],
     ["A-B","C-D","E-F","G-H","I-J","K-L","M-N","O-P","Q-R","S-T","U-V","W-Z"],
     ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q-R","S","T","U-V","W-X","Y-Z"]
  ]
  RECORDS_PER_RANGE = 750000
  FILES_PER_PAGE = 500
  MAX_RECORDS_COORDINATOR = 4000
  MAX_RECORDS_DATA_MANAGER = 15000 
  MAX_RECORDS_SYSTEM_ADMINISTRATOR = 100000 

end
