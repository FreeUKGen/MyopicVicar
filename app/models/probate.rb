# frozen_string_literal: true
class Probate
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :id, type: String
  embeds_one :divs
  embeds_one :deaths
  embeds_one :events

  class Div
    include Mongoid::Document
    field :p, type: String
  end

  class Death
    include Mongoid::Document
    embeds_one :names
    field :address, type: String
    field :date, type: Date
    field :place, type: String
  end

  class Event
    include Mongoid::Document
    field :court, type: String
    field :date, type: Date
    field :person, type: Array
    field :value, type: String
  end

  class Administration < Event
    include Mongoid::Document
  end
  class Confirmation < Event
    include Mongoid::Document
  end
  class Probate < Event
    include Mongoid::Document
  end
  class Name
    include Mongoid::Document
    field :LastName, type: String
    field :GivenName, type: String
  end

end
