class ManageCounty

  include Mongoid::Document
  field :chapman_code, type: String
  field :action, type: Array
  field :places, type: String

  require 'freereg_options_constants'

  class << self


    def get_not_processed_files_for_county(county)
      #rspec tested
      possible_batches = PhysicalFile.uploaded_into_base.not_processed.not_waiting.all.order_by("userid ASC, base_uploaded_date DESC")
      batches =[]
      possible_batches.each do |batch|
        batches << batch if Freereg1CsvFile.file_name(batch.file_name).county(ChapmanCode.merge_countries[(county)]).present?
      end
      batches
    end

    def get_waiting_files_for_county(county)
      #rspec tested
      possible_batches = PhysicalFile.waiting.all.order_by("userid ASC, waiting_date DESC")
      batches =[]
      possible_batches.each do |batch|
        batches << batch if Freereg1CsvFile.file_name(batch.file_name).county(ChapmanCode.merge_countries[(county)]).present?
      end
      batches
    end


    def records(chapman,alphabet)
      #if alphabet is present we have already been through
      number = 0
      if alphabet.present?
        number = alphabet
      else
        county = County.chapman_code(chapman).first
        total = county.total_records unless county.nil?
        total_places = Place.chapman_code(chapman).count/100
        if total.present?
          number = total.to_i
          number = (number/FreeregOptionsConstants::RECORDS_PER_RANGE).to_i >= total_places ?  number = (number/FreeregOptionsConstants::RECORDS_PER_RANGE).to_i : number = total_places
          number = FreeregOptionsConstants::ALPHABETS.length - 1 if number >= FreeregOptionsConstants::ALPHABETS.length
        else
          number = 1
        end

      end
      number
    end

  end
end
