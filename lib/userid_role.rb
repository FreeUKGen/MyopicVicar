module UseridRole

  def self.name_from_code(code)
    CODES.invert[code]
  end

  
  def self.values
    CODES::values
  end
  def self.has_key?(code)
    CODES.has_key?(code)
  end

  def self.values_at(value)
    array = CODES.values_at(value)
    array[0]
  end
  
  def self.select_hash
    CODES
  end
  
  def self.select_hash_with_parenthetical_codes
    Hash[UseridRole::CODES.map { |k,v| ["#{k} (#{v})", v] }]
  end

  def self.has_key(value)
    CODES.key(value)
  end
  
  CODES = {
   'researcher' => "Results", 
   'trainee' => "Profile",
   'transcriber' => "Files", 
   'syndicate_coordinator' => "Syndicate", 
   'county_coordinator' => "County",
   'country_coordinator' => "Country",
   'volunteer_coordinator' => "All people",
   'system_administrator' => "All Assets", 
   'data_manager' => "All Data" 
  }
end