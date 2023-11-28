# Open the Refinery::Page model for manipulation
#require Rails.root.join('lib', 'devise', 'encryptors', 'md5')

Refinery::Authentication::Devise::User.class_eval do

  devise  :encryptable, :encryptor => :freereg
  #  before_update :inform_coordinator_of_completion_and_update_userid

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

  def downcase_username
    self.username = self.username #no-op for case-sensitive usernames
  end


  def inform_coordinator_of_completion_and_update_userid
    if self.changed.include?('encrypted_password')
      userid = UseridDetail.id(self.userid_detail_id).first
      logger.warn "FREEREG::USER updating encrypted_password for #{userid.userid}" if userid.present?
      logger.warn "FREEREG::USER missing userid for #{userid_detail_id}" if userid.blank?

      #we send coordinator email on an initial password setting
      userid.finish_transcriber_creation_setup if userid.present? && userid.person_role == 'transcriber' &&
        self.encrypted_password != Devise::Encryptable::Encryptors::Freereg.digest('temppasshope',nil,nil,nil) &&
        userid.password_confirmation == Devise::Encryptable::Encryptors::Freereg.digest('temppasshope',nil,nil,nil) &&  userid.password == Devise::Encryptable::Encryptors::Freereg.digest('temppasshope',nil,nil,nil)
      userid.password = self.encrypted_password
      userid.save!
      userid.write_userid_file
    end
  end
  private

  def userid_detail_params
    # It's mandatory to specify the nested attributes that should be whitelisted.
    # If you use `permit` with just the key that points to the nested attributes hash,
    # it will return an empty hash.
    params.require(:person).permit(:name, :age, pets_attributes: [ :name, :category ])
  end



  #  def email_required?
  #    false
  #  end

end
