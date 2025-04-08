# frozen_string_literal: true

class Event
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  field :PersonId, type: String
  field :Type, type: String
  field :Court, type: String
  field :Date, type: String
  field :Value, type: String
end

