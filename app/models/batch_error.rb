# Stores the error that we detected in an entry
class BatchError
  include Mongoid::Document
  field :record_type, type: String
  field :record_number, type: Integer
  field :field_number, type: Integer
  field :error_message, type: String
  field :field, type: String
  field :error_type, type: String
  field :data_line, type: Hash
  field :entry_id, type: String
  belongs_to :freereg1_csv_file, index: true
  index(entry_id: 1)
  index(freereg1_csv_file_id: 1, entry_id: 1)

  class << self
    def id(id)
      where(id: id)
    end
  end

  def adjust_data_line
    data_line[:record_type] = record_type
    data_line.delete(:chapman_code)
    data_line.delete(:place_name)
    self
  end
end
