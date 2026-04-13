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

  include Mongoid::Timestamps

  # for more on this voodoo, see http://gistflow.com/posts/749-canceling-validations-in-activerecord
  def self.remove_email_uniq_validation
    email_uniq_validation = _validators[:email].find{ |validator| validator.is_a? ActiveRecord::Validations::UniquenessValidator }
    _validators[:email].delete(email_uniq_validation)
    filter = _validate_callbacks.find{ |c| c.raw_filter == email_uniq_validation }
    skip_callback :validate, filter
  end

  def self.find_first_by_auth_conditions_o(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
      self.any_of({ :username =>  /^#{::Regexp.escape(login)}$/i }, { :email =>  /^#{::Regexp.escape(login)}$/i }).first
    else
      super
    end
  end

  # Validate and sanitize login input
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  # Match legacy UseridDetail.userid values (that field has no format validator).
  # Disallow ASCII control chars only so migration (rake freeuk:add_user) can import all members.
  validates :username, presence: true, uniqueness: { case_sensitive: false },
            format: { with: /\A[^\x00-\x1f\x7f]+\z/, message: "must not contain control characters" }


  # Override Devise method to find user by login (email or username)
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions. dup
    
    if (login = conditions.delete(:login))
      sanitized_login = sanitize_login(login)
      return nil unless sanitized_login
      
      # SAFE:  Mongoid automatically escapes values
      where(conditions).or(
        { email: sanitized_login },
        { username:  sanitized_login }
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
      
      # SAFE: Mongoid automatically escapes values - call . or on where()
      where({}).or(
        { email: sanitized_login },
        { username: sanitized_login }
      ).first
    else
      where(conditions).first
    end
  end

  # Sanitize login input
  def self.sanitize_login(login)
    return nil if login.blank?
    
    # Sanitize: strip whitespace and convert to lowercase
    sanitized = login.to_s.strip.downcase
    
    # Return nil if empty or too long (prevent DoS)
    return nil if sanitized.blank? || sanitized. length > 255
    
    sanitized
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
   # send_devise_notification(:reset_password_instructions, raw)
    UserMailer.reset_password_instructions(self, raw).deliver_now
    raw
  end
  
  def valid_password?(password)
    return false if encrypted_password.blank?

    # Use the Freereg encryptor directly
    encrypted_input = Devise:: Encryptable::Encryptors::Freereg.digest(password, nil, nil, nil)

    # Compare with stored encrypted password
    encrypted_input == encrypted_password
  end

  def after_database_authentication
    user = self.userid_detail
    user.update_attribute(:password, self.encrypted_password)
  end


  def password_digest(pass)
    Devise:: Encryptable::Encryptors::Freereg.digest(pass, nil, nil, nil)
  end

  protected

  def send_devise_notification(notification, *args)
    # Extract arguments - Devise passes (token, opts_hash) or just (token)
    # Don't flatten - ActionMailer is very sensitive to argument format
    token = args[0]
    opts = args[1] || {}
    
    case notification.to_sym
    when :reset_password_instructions
      # Ensure token is present and convert to string
      raise ArgumentError, "Token is required for reset_password_instructions" if token.blank?
      token = token.to_s
      
      # Get the mailer method and call it directly using method.call
      # This bypasses ActionMailer's argument processing that's causing the error
      mailer_class = Devise.mailer
      mailer_method = mailer_class.method(:reset_password_instructions)
      
      # Call with exactly the arguments ActionMailer expects
      if opts.is_a?(Hash) && opts.any?
        message = mailer_method.call(self, token, opts)
      else
        message = mailer_method.call(self, token)
      end
      
    when :confirmation_instructions
      raise ArgumentError, "Token is required for confirmation_instructions" if token.blank?
      token = token.to_s
      opts = opts.is_a?(Hash) ? opts : {}
      mailer_class = Devise.mailer
      mailer_method = mailer_class.method(:confirmation_instructions)
      message = mailer_method.call(self, token, opts)
      
    else
      # For other notifications, use method lookup
      mailer_class = Devise.mailer
      if mailer_class.respond_to?(notification)
        mailer_method = mailer_class.method(notification)
        message = mailer_method.call(self, *args)
      else
        raise NotImplementedError, "Notification #{notification} is not supported"
      end
    end
    
    # Deliver the message
    # The error "arguments expected to be an Array of individual string args" 
    # comes from sendmail delivery method configuration
    # Use deliver_now which should work correctly with proper sendmail settings
    message.deliver_now
  end

  private

  def userid_detail_params
    # It's mandatory to specify the nested attributes that should be whitelisted.
    # If you use `permit` with just the key that points to the nested attributes hash,
    # it will return an empty hash.
    params.require(:person).permit(:name, :age, pets_attributes: [ :name, :category ])
  end

end