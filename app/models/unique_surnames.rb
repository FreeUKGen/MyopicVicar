class UniqueSurname
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  field :Name, type: String
  field :count, type: Integer
end

