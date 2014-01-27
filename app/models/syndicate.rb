class Syndicate
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short

  field :syndicate_code, type: String
  field :creation_date, type: DateTime
  field :enabled_date, type: DateTime
  field :last_updated_date, type: DateTime
  field :active, type: Boolean, default: true
  field :disabled_date, type: DateTime
  field :disabled_reason, type: String
  field :syndicate_coordinator, type: String
  field :syndicate_description, type: String
  field :syndicate_notes, type: String
 
 index ({ syndicate_code: 1, syndicate_coordinator: 1 })

end
