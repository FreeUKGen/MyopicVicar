class BatchError
  include Mongoid::Document
  field :record_type, type: String
  field :record_number, type: Integer
  field :field_number, type: Integer
  field :error_message, type: String
  field :field, type: String
  field :error_type, type: String
  field :data_line, type: Array
  field :entry_id, type: String
  belongs_to  :freereg1_csv_file, index: true
  index({entry_id:1})
end