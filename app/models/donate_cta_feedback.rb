class DonateCtaFeedback
  include Mongoid::Document
  include Mongoid::Timestamps
  require 'app'

  field :body, type: String
  field :name, type: String
  field :email_address, type: String
  field :identifier, type: String

  validate :feedback_form
  validates :email_address, format: { with: Devise::email_regexp, message: "Please provide a valid email address." }
  before_create :add_identifier

  def feedback_form
    self.errors.add(:name, "Please provide your name.") if self.name.blank?
    self.errors.add(:email_address, "Please provide a valid email address.") if self.email_address.blank?
    self.errors.add(:body, "Please provide the feedback content.") if self.body.blank?
  end

  def add_identifier
    self.identifier = Time.now.to_i - Time.gm(2015).to_i
  end

  def complete_process
  	self.acknowledge_communication
    self.contact_action_communication
  end

  def acknowledge_communication
    UserMailer.acknowledge_donate_cta_feedback(self).deliver_now
  end

  def contact_action_communication
    UserMailer.communicate_donate_cta_feedback(self).deliver_now
  end

end
