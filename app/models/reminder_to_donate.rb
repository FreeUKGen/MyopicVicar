class ReminderToDonate
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :email, type: String
  field :reminded, type: Boolean, default: false
   
end
