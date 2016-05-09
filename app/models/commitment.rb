class Commitment

  include Mongoid::Document

  embedded_in :software_version

  attr_accessor :commitment_number, :author, :date_committed, :commitment_message

  field :commitment_number, type: String
  field :author, type: String
  field :date_committed, type: String
  field :commitment_message, type: String

 
end
