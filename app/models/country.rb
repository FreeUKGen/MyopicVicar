class Country
   include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short

  field :chapman_code, type: String
  field :creation_date, type: DateTime
  field :enabled_date, type: DateTime
  field :last_updated_date, type: DateTime
  field :active, type: Boolean, default: true
  field :disabled_date, type: DateTime
  field :disabled_reason, type: String
  field :country_coordinator, type: String
  field :country_description, type: String
  field :country_notes, type: String
  field :counties_included, type: Array

  index ({ chapman_code: 1, country_coordinator: 1,counties_included: 1 })
end
