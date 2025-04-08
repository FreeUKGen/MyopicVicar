# frozen_string_literal: true

class Executor
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  embedded_in :probate
  field :PersonId, type: String
  field :FullName, type: String
  field :LastName, type: String
  field :GivenName, type: String
  field :Role, type: String
  field :Note, type: String

  def new
    self.build
  end
end
