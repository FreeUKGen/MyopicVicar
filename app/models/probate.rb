# frozen_string_literal: true
class Probate
  include Mongoid::Document

  field :id, :type => String
  embeds_one :divs
  embeds_one :deaths
  embeds_one :administrations

  class Div
    include Mongoid::Document
    field :p, :type => String
  end

  class Death
    include Mongoid::Document
    embeds_one :names
    field :address, type: String
    field :date, type: Date
    field :place, type: String
  end

  class Administration
    include Mongoid::Document
    field :court, type: String
    field :date, type: Date
  end

  class Name
    include Mongoid::Document
    field :LastName, type: String
    field :GivenName, type: String
  end

end
