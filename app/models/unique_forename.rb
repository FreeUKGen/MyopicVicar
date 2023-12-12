class UniqueForename
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  field :Name, type: String
  field :count, type: Integer
  index( {Name: 1}, {background: true})
end