class ManageSyndicate
  include Mongoid::Document
 field :syndicate, type: String
 field :action, type: Array
 field :userid, type: String
field :email_address, type: String

end
