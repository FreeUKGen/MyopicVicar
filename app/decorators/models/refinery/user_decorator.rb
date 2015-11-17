# Open the Refinery::Page model for manipulation
require Rails.root.join('lib', 'devise', 'encryptors', 'md5')

Refinery::User.class_eval do
  attr_accessible :userid_detail_id
  devise :encryptable, :encryptor => :freereg

  after_update :save_password_and_send_notification 


  # for more on this voodoo, see http://gistflow.com/posts/749-canceling-validations-in-activerecord
  def self.remove_email_uniq_validation
    email_uniq_validation = _validators[:email].find{ |validator| validator.is_a? ActiveRecord::Validations::UniquenessValidator }
    _validators[:email].delete(email_uniq_validation)
    filter = _validate_callbacks.find{ |c| c.raw_filter == email_uniq_validation }
    skip_callback :validate, filter
  end


  remove_email_uniq_validation


  def userid_detail
    UseridDetail.find(self.userid_detail_id)
  end


  def downcase_username
    self.username = self.username #no-op for case-sensitive usernames
  end

  def save_password_and_send_notification
    if self.changed.include?('encrypted_password')
      userid = UseridDetail.find(self.userid_detail_id)
      userid.password = self.encrypted_password
      userid.save!
      userid.write_userid_file
      
      UserMailer.notification_of_registration_completion(userid).deliver 
    end
  end
  #  def email_required?
#    false
#  end

end
