class User
  include Mongoid::Document
  include Mongoid::Timestamps

  # Devise modules
  devise :database_authenticatable, :registerable,
         : recoverable, :rememberable, : validatable
  devise :encryptable, encryptor: :freereg

  attr_writer :login

  ## Database authenticatable
  field :username, type: String
  field : email, type: String, default: ""
  field :encrypted_password, type: String, default: ""
  field :password_salt, type:  String
  field :userid_detail_id, type: String

  ## Recoverable
  field : reset_password_token, type: String
  field :reset_password_sent_at, type: Time

  ## Rememberable
  field :remember_created_at, type: Time

  ## Trackable
  field :sign_in_count, type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field : last_sign_in_at, type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip, type:  String

  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :username, presence: true, uniqueness: { case_sensitive: false },
            format: { with:  /\A[a-zA-Z0-9_\-@. ]+\z/, message: "only allows letters, numbers, and basic symbols" }

  # Override Devise method to find user by login (email or username)
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions. dup
    
    if (login = conditions.delete(:login))
      sanitized_login = sanitize_login(login)
      return nil unless sanitized_login
      
      # Mongoid automatically escapes values
      where(conditions).or(
        { email: sanitized_login },
        { username: sanitized_login }
      ).first
    elsif conditions.key? (:email) || conditions.key?(:username)
      where(conditions).first
    end
  end

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    
    if (login = conditions.delete(:login))
      sanitized_login = sanitize_login(login)
      return nil unless sanitized_login
      
      # Mongoid automatically escapes values
      where({}).or(
        { email: sanitized_login },
        { username: sanitized_login }
      ).first
    else
      where(conditions).first
    end
  end

  # Sanitize login input
  def self. sanitize_login(login)
    return nil if login.blank? 
    
    sanitized = login.to_s. strip.downcase
    
    # Return nil if empty or too long (prevent DoS)
    return nil if sanitized.blank? || sanitized. length > 255
    
    sanitized
  end

  def userid_detail
    UseridDetail.find(userid_detail_id)
  end

  def downcase_username
    self.username = username # no-op for case-sensitive usernames
  end

  def inform_coordinator_of_completion_and_update_userid
    return unless changed.include?('encrypted_password')
    
    userid = UseridDetail.id(userid_detail_id).first
    
    if userid.present?
      logger.warn "FREEREG::USER updating encrypted_password for #{userid.userid}"
      
      # Send coordinator email on initial password setting
      temp_password_digest = Devise::Encryptable::Encryptors:: Freereg.digest('temppasshope', nil, nil, nil)
      
      if userid.person_role == 'transcriber' &&
         encrypted_password != temp_password_digest &&
         userid.password_confirmation == temp_password_digest &&
         userid.password == temp_password_digest
        userid.finish_transcriber_creation_setup
      end
      
      userid.password = encrypted_password
      userid. save!
      userid.write_userid_file
    else
      logger.warn "FREEREG::USER missing userid for #{userid_detail_id}"
    end
  end

  def login
    @login || username || email
  end

  def will_save_change_to_email?
    # Mongoid compatibility method - no-op
  end

  def generate_reset_password_token
    raw, enc = Devise.token_generator. generate(self.class, :reset_password_token)
    self.reset_password_token = enc
    self.reset_password_sent_at = Time.now. utc
    save(validate: false)
    
    UserMailer.reset_password_instructions(self, raw).deliver_now
    raw
  end

  def valid_password?(password)
    return false if encrypted_password.blank? 

    # Use the Freereg encryptor directly
    encrypted_input = Devise::Encryptable::Encryptors:: Freereg.digest(password, nil, nil, nil)

    # Compare with stored encrypted password
    encrypted_input == encrypted_password
  end

  def password_digest(pass)
    Devise::Encryptable::Encryptors::Freereg.digest(pass, nil, nil, nil)
  end

  protected

  def send_devise_notification(notification, *args)
    token = args[0]
    opts = args[1] || {}
    
    raise ArgumentError, "Token is required for #{notification}" if token.blank? 
    token = token.to_s
    
    mailer_class = Devise.mailer
    message = case notification. to_sym
              when :reset_password_instructions
                mailer_class.reset_password_instructions(self, token, opts)
              when :confirmation_instructions
                mailer_class.confirmation_instructions(self, token, opts)
              else
                raise NotImplementedError, "Notification #{notification} is not supported"
              end
    
    message.deliver_now
  end
end