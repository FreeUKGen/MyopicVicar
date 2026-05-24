# frozen_string_literal: true

# Devise-backed member login (Mongoid). Replaces Refinery::Authentication::Devise::User for authentication.
class User
    include Mongoid::Document
  
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :validatable
    devise :encryptable, encryptor: :freereg
  
    before_update :inform_coordinator_of_completion_and_update_userid
  
    attr_writer :login
  
    field :username, type: String
    field :email, type: String, default: ''
    field :encrypted_password, type: String, default: ''
    field :password_salt, type: String
    field :userid_detail_id, type: String
  
    field :reset_password_token, type: String
    field :reset_password_sent_at, type: Time
  
    field :remember_created_at, type: Time
  
    field :sign_in_count, type: Integer, default: 0
    field :current_sign_in_at, type: Time
    field :last_sign_in_at, type: Time
    field :current_sign_in_ip, type: String
    field :last_sign_in_ip, type: String
  
    include Mongoid::Timestamps
  
    validates :email, presence: true, uniqueness: { case_sensitive: false }
    validates :username, presence: true, uniqueness: { case_sensitive: false },
              format: { with: /\A[^\x00-\x1f\x7f]+\z/, message: 'must not contain control characters' }
  
    def self.find_for_database_authentication(warden_conditions)
      find_first_by_auth_conditions(warden_conditions)
    end
  
    def self.find_first_by_auth_conditions(warden_conditions)
      conditions = warden_conditions.respond_to?(:with_indifferent_access) ? warden_conditions.with_indifferent_access.dup : warden_conditions.dup
  
      if (login = conditions.delete(:login))
        stripped = sanitize_login(login)
        return nil unless stripped
  
        scope = conditions.blank? ? all : where(conditions.to_h)
        email_criteria = { email: /\A#{::Regexp.escape(stripped)}\z/i }
  
        if stripped.include?('@')
          scope.or(email_criteria).first
        else
          scope.or(email_criteria, { username: /\A#{::Regexp.escape(stripped)}\z/i }).first
        end
      elsif (email = conditions[:email]).present?
        email = email.to_s.strip
        remainder = conditions.except(:email, 'email')
        scope = remainder.blank? ? all : where(remainder.to_h)
        scope.or(email: /\A#{::Regexp.escape(email)}\z/i).first
      else
        where(conditions.to_h).first
      end
    end
  
    def self.sanitize_login(login)
      return nil if login.blank?
  
      sanitized = login.to_s.strip
      return nil if sanitized.blank? || sanitized.length > 255
  
      sanitized
    end
  
    def userid_detail
      UseridDetail.find(userid_detail_id)
    end
  
    def downcase_username
      self.username = username
    end
  
    def inform_coordinator_of_completion_and_update_userid
      return unless changed.include?('encrypted_password')
  
      userid = UseridDetail.id(userid_detail_id).first
      logger.warn "FREEREG::USER updating encrypted_password for #{userid.userid}" if userid.present?
      logger.warn "FREEREG::USER missing userid for #{userid_detail_id}" if userid.blank?
  
      temppass = Devise::Encryptable::Encryptors::Freereg.digest('temppasshope', nil, nil, nil)
      if userid.present? && userid.person_role == 'transcriber' &&
         encrypted_password != temppass &&
         userid.password_confirmation == temppass && userid.password == temppass
        userid.finish_transcriber_creation_setup
      end
      return if userid.blank?
  
      userid.password = encrypted_password
      userid.save!
      userid.write_userid_file
    end
  
    def login
      @login || username || email
    end
  
    # Devise 4 + Mongoid: silence email reconfirmation checks not used for this model.
    def will_save_change_to_email?
      false
    end
  
    def valid_password?(password)
      return false if encrypted_password.blank?
  
      encrypted_input = Devise::Encryptable::Encryptors::Freereg.digest(password, nil, nil, nil)
      encrypted_input == encrypted_password
    end
  
    def after_database_authentication
      user = userid_detail
      user.update_attribute(:password, encrypted_password)
    end
  
    def password_digest(pass)
      Devise::Encryptable::Encryptors::Freereg.digest(pass, nil, nil, nil)
    end
end