class ReminderToDonate
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :email, type: String
  field :reminded, type: Boolean, default: false

  index({ email_address: 1 })
  validates_presence_of :email, message: "Please provide your email address."
  validates_format_of :email, with: Devise::email_regexp, message: "Please provide proper email"
end
