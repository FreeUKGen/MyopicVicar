class User
  include Mongoid::Document
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  devise  :encryptable, :encryptor => :freereg
  #alias devise_will_save_change_to_email? will_save_change_to_email?
  attr_writer :login
  ## Database authenticatable
  field :username, type: String
  field :email,              type: String, default: ""
  field :encrypted_password, type: String, default: ""
  field :password_salt, type: String
  field :userid_detail_id, type: String

  ## Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time

  ## Rememberable
  field :remember_created_at, type: Time

  ## Trackable
  field :sign_in_count,      type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,    type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,    type: String

  ## Confirmable
  # field :confirmation_token,   type: String
  # field :confirmed_at,         type: Time
  # field :confirmation_sent_at, type: Time
  # field :unconfirmed_email,    type: String # Only if using reconfirmable

  ## Lockable
  # field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  # field :unlock_token,    type: String # Only if unlock strategy is :email or :both
  # field :locked_at,       type: Time
  include Mongoid::Timestamps

  # for more on this voodoo, see http://gistflow.com/posts/749-canceling-validations-in-activerecord
  def self.remove_email_uniq_validation
    email_uniq_validation = _validators[:email].find{ |validator| validator.is_a? ActiveRecord::Validations::UniquenessValidator }
    _validators[:email].delete(email_uniq_validation)
    filter = _validate_callbacks.find{ |c| c.raw_filter == email_uniq_validation }
    skip_callback :validate, filter
  end

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
      self.any_of({ :username =>  /^#{::Regexp.escape(login)}$/i }, { :email =>  /^#{::Regexp.escape(login)}$/i }).first
    else
      super
    end
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

  def login
    @login || self.username || self.email
  end

  def will_save_change_to_email?
  end

  def generate_reset_password_token
    raw, enc = Devise.token_generator.generate(self.class, :reset_password_token)
    self.reset_password_token   = enc
    self.reset_password_sent_at = Time.now.utc
    self.save(validate: false)
    send_devise_notification(:reset_password_instructions, raw, {})
    raw
  end

  private

  def userid_detail_params
    # It's mandatory to specify the nested attributes that should be whitelisted.
    # If you use `permit` with just the key that points to the nested attributes hash,
    # it will return an empty hash.
    params.require(:person).permit(:name, :age, pets_attributes: [ :name, :category ])
  end

end