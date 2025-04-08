# frozen_string_literal: true
class Probate
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :PersonId, type: String
  field :P, type: String
  field :SourceImage, type: String
  embeds_one :death
  embeds_one :event
  has_many :executors
  accepts_nested_attributes_for :death, :event, :executors

  def build
    #self.Death ||= Death.new
    #self.Event ||= Event.new
    self
  end

end


# following class no longer required (but kept 'just in case'):

class Name
  include Mongoid::Document
  field :LastName, type: String
  field :GivenName, type: String
  field :Role, type: String
end


