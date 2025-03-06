# frozen_string_literal: true

class Executor
  include Mongoid::Document
  field :LastName, type: String
  field :GivenName, type: String
  field :Role, type: String
end
