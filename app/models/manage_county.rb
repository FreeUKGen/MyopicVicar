class ManageCounty
  include Mongoid::Document
 field :chapman_code, type: String
 field :actions, type: Array
 field :places, type: String
end
