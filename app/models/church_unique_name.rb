class ChurchUniqueName
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  field :unique_surnames, type: Array
  field :unique_forenames, type: Array
  belongs_to :church, index: true
end
