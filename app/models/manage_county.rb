class ManageCounty

  include Mongoid::Document
  field :chapman_code, type: String
  field :action, type: Array
  field :places, type: String

  require 'freereg_options_constants'



  def self.get_waiting_files_for_county(county)
    #rspec tested
    possible_batches = PhysicalFile.waiting.all.order_by("userid ASC, waiting_date DESC")
    batches =[]
    possible_batches.each do |batch|
      batches << batch if Freereg1CsvFile.file_name(batch.file_name).county(ChapmanCode.merge_countries[(county)]).present?
    end
    batches
  end

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
