class County
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
  field :county_coordinator, type: String
  field :county_description, type: String
  field :county_notes, type: String

  index ({ chapman_code: 1, county_coordinator: 1 })
end
