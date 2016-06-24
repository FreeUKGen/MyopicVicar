class ManageCounty

  include Mongoid::Document
  field :chapman_code, type: String
  field :action, type: Array
  field :places, type: String

  require 'freereg_options_constants'

  def self.records(chapman,alphabet)
    #if alphabet is present we have already been through
    number = 0
    if alphabet.blank?
      county = County.chapman_code(chapman).first
      total = county.total_records unless county.nil?
      if total.present?
        number = total.to_i
        number = (number/FreeregOptionsConstants::RECORDS_PER_RANGE).to_i
        number = FreeregOptionsConstants::ALPHABETS.length - 1 if number >= FreeregOptionsConstants::ALPHABETS.length
      else
        total = 0
      end
    else
      number = alphabet
    end
    number
  end

end
