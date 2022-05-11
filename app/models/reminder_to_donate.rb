class ReminderToDonate
  include Mongoid::Document
  include Mongoid::Timestamps
  require 'app'
  
  field :name, type: String
  field :email, type: String
  #attr_accessor :name, :email
  validate :reminder_form
  validates :email, format: { with: Devise::email_regexp, message: "Please provide a valid email address." }#, , on: :create
  
  def reminder_form
    self.errors.add(:name, "Please provide your name.") if self.name.blank?
    self.errors.add(:email, "Please provide a valid email address.") if self.email.blank?
  end
end
