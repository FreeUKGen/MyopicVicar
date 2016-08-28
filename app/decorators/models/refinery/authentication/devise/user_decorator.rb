# Open the Refinery::Page model for manipulation
#require Rails.root.join('lib', 'devise', 'encryptors', 'md5')

Refinery::Authentication::Devise::User.class_eval do
  attr_accessible :userid_detail_id, :reset_password_token, :reset_password_sent_at
  devise :timeoutable , :encryptable, :encryptor => :freereg
  before_update :inform_coordinator_of_completion
  after_update :save_password_and_send_notification

  # for more on this voodoo, see http://gistflow.com/posts/749-canceling-validations-in-activerecord
  def self.remove_email_uniq_validation
    email_uniq_validation = _validators[:email].find{ |validator| validator.is_a? ActiveRecord::Validations::UniquenessValidator }
    _validators[:email].delete(email_uniq_validation)
    filter = _validate_callbacks.find{ |c| c.raw_filter == email_uniq_validation }
    skip_callback :validate, filter
  end

  def userid_detail

    UseridDetail.find(self.userid_detail_id)
  end
  def timeout_in
    10.minute
  end


  def downcase_username
    self.username = self.username #no-op for case-sensitive usernames
  end

  def inform_coordinator_of_completion
    userid = UseridDetail.find(self.userid_detail_id)
    userid.finish_transcriber_creation_setup if userid.person_role == 'transcriber' &&
      self.encrypted_password != Devise::Encryptable::Encryptors::Freereg.digest('temppasshope',nil,nil,nil) &&
      userid.password == Devise::Encryptable::Encryptors::Freereg.digest('temppasshope',nil,nil,nil)
  end

  def save_password_and_send_notification
    self.userid_detail_id
    if self.changed.include?('encrypted_password')
      userid = UseridDetail.find(self.userid_detail_id)
      userid.password = self.encrypted_password
      userid.save!
      userid.write_userid_file

      #UserMailer.notification_of_registration_completion(userid).deliver
      #best done by application
    end
  end


  #  def email_required?
  #    false
  #  end

end
