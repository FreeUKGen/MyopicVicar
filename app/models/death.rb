# frozen_string_literal: true

class Death
  include Mongoid::Document
  field :LastName, type: String
  field :GivenName, type: String
  field :Address, type: String
  field :Role, type: String
  field :Date, type: String
  field :Place, type: String
end
