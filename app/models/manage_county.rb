class ManageCounty
  include Mongoid::Document
  field :chapman_code, type: String
  field :action, type: Array
  field :places, type: String
  
  def self.files(chapman,alphabet)
    #if alphabet is present we have already been through
    number = 0
    if alphabet.blank? 
      Place.chapman_code(chapman).each do |place|
        number = number + place.search_records.count 
      end
      number = (number/FreeregOptionsConstants::RECORDS_PER_RANGE).to_i
      number = FreeregOptionsConstants::ALPHABETS.length - 1 if number >= FreeregOptionsConstants::ALPHABETS.length
    else
      number = alphabet
    end
    number
  end
  
end
