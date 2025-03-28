# frozen_string_literal: true
class Probate
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :PersonId, type: String
  field :P, type: String
  #embeds_one :div
  embeds_one :death
  embeds_one :event

  class Death
    include Mongoid::Document
    #embeds_one :name
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

  class Div
    include Mongoid::Document
    field :p, type: String
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
