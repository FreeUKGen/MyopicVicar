class DistrictUniqueName
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  field :unique_surnames, type: Array
  field :unique_forenames, type: Array
  field :record_type, type: Integer
  field :district_number, type: Integer
  index({ district_number: 1, record_type: 1 }, { name: 'record_type_district' })
end