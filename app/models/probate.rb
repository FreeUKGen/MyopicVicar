# frozen_string_literal: true
class Probate
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :PersonId, type: String
  field :p, type: String
  #embeds_one :divs
  embeds_one :deaths
  embeds_one :events

  class Div
    include Mongoid::Document
    field :p, type: String
  end

  class Death
    include Mongoid::Document
    #embeds_one :names
    field :LastName, type: String
    field :GivenName, type: String
    field :Address, type: String
    field :Date, type: Date
    field :Place, type: String
  end

  class Event
    include Mongoid::Document
    field :Type, type: String
    field :Court, type: String
    field :Date, type: Date
    field :person, type: Array
    field :Value, type: String
  end

  # following classes are no longer required (but have been kept 'just in case'):
  #
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
