# frozen_string_literal: true
class Probate
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :PersonId, type: String
  field :P, type: String
  field :SourceImage, type: String
  embeds_one :death
  embeds_one :event
  accepts_nested_attributes_for :death, :event

  def build
    self.Death ||= Death.new
    self.Event ||= Event.new
  end

end

class Death
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  embedded_in :probate
  field :LastName, type: String
  field :GivenName, type: String
  field :Address, type: String
  field :Role, type: String
  field :Date, type: String
  field :Year, type: Integer
  field :Place, type: String
  field :Note, type: String
end

class Event
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  embedded_in :probate
  field :Type, type: String
  field :Court, type: String
  field :Date, type: String
  field :Year, type: Integer
  field :person, type: Array
  field :Value, type: String
  field :Note, type: String
  embeds_many :executors
  accepts_nested_attributes_for :executors, :allow_destroy => true
end

class Executor
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  embedded_in :event
  field :Name, type: String
  field :Role, type: String
  field :Note, type: String
end

# following class no longer required (but kept 'just in case'):

class Name
  include Mongoid::Document
  field :LastName, type: String
  field :GivenName, type: String
  field :Role, type: String
end


