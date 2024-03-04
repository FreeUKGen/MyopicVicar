class SearchName
  include Mongoid::Document
  field :first_name, type: String
  field :last_name, type: String
  field :origin, type: String
  field :role, type: String
  field :gender, type: String #m=male, f=female, nil=not specified
  field :type, type: String


  def contains_wildcard_ucf?
    result = UcfTransformer.contains_wildcard_ucf?(self.first_name) || UcfTransformer.contains_wildcard_ucf?(self.last_name)
    result
  end
end
