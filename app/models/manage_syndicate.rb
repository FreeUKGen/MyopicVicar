class ManageSyndicate
  include Mongoid::Document
 field :syndicate, type: String
 field :action, type: Array

end
