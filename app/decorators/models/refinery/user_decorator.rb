# Open the Refinery::Page model for manipulation
require Rails.root.join('lib', 'devise', 'encryptors', 'md5')

Refinery::User.class_eval do
  attr_accessible :userid_detail_id
  devise :encryptable, :encryptor => :freereg


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
    self.username=self.username #no-op for case-sensitive usernames
  end

#  def email_required?
#    false
#  end

end
