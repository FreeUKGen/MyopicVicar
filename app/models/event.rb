# frozen_string_literal: true

class Event
  include Mongoid::Document
  field :Type, type: String
  field :Court, type: String
  field :Date, type: String
  field :person, type: Array
  field :Value, type: String
end
