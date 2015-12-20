class ManageCounty
  include Mongoid::Document
  field :chapman_code, type: String
  field :action, type: Array
  field :places, type: String
  
   def self.records(chapman,alphabet)
    #if alphabet is present we have already been through
    number = 0
    if alphabet.blank? 
      county = County.chapman_code(chapman).first
      number = county.total_records.to_i
      number = (number/FreeregOptionsConstants::RECORDS_PER_RANGE).to_i
      number = FreeregOptionsConstants::ALPHABETS.length - 1 if number >= FreeregOptionsConstants::ALPHABETS.length
    else
      number = alphabet
    end
    number
  end
  
end
