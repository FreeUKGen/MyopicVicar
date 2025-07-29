class RecordStatistic
	include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  field :database_name
  field :table_name
  field :record_type, type: Integer
  field :total_records, type: Integer
  #index({ district_number: 1, record_type: 1 }, { name: 'record_type_district' })
end