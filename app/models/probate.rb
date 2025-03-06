# frozen_string_literal: true
class Probate
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  field :PersonId, type: String
  field :p, type: String
  field :person, type: Array
  embeds_one :death
  embeds_one :event
  embeds_many :executors

  accepts_nested_attributes_for :death, :event, :executors

 end
