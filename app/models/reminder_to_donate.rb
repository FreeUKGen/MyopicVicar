class ReminderToDonate
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, type: String
  field :email, type: String


  index({ email_address: 1 })
  validates_presence_of :email, message: "Please provide your email address.", on: :create
  validates_presence_of :name, message: "Please provide your name.", on: :create
  validates_format_of :email, with: Devise::email_regexp, message: "Please provide proper email", on: :create
end
