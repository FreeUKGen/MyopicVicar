class UseridDetail
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short

  require 'freereg_options_constants'

  field :userid, type: String
  field :userid_lower_case, type: String
  field :syndicate, type: String
  field :submitter_number, type: String
  field :person_surname, type: String
  field :person_forename, type: String
  field :email_address, type: String
  field :email_address_confirmation, type: String
  field :address, type: String
  field :telephone_number, type: String
  field :skill_level, type: String, default: 'Unspecified'
  field :fiche_reader, type: Boolean
  field :password, type: String
  field :password_confirmation, type: String
  field :previous_syndicate, type: String
  field :active, type: Boolean
  field :last_upload, type: DateTime
  field :number_of_files, type: Integer, default: 0 # not being used for display
  field :number_of_records, type: Integer, default: 0 # not being used for display
  field :sign_up_date, type: DateTime
  field :disabled_date, type: DateTime
  field :disabled_reason_standard, type: String
  field :disabled_reason, type: String
  field :person_role, type: String, default: 'researcher'
  field :syndicate_groups, type: Array
  field :county_groups, type: Array
  field :country_groups, type: Array
  field :digest, type: String, default: nil
  field :skill_notes, type: String
  field :transcription_agreement, type: String, default: 'Unknown'
  field :technical_agreement, type: Boolean, default: false
  field :research_agreement, type: Boolean, default: false
  field :email_address_valid, type: Boolean, default: true
  field :email_address_last_confirmned, type: DateTime
  field :no_processing_messages, type: Boolean, default: false
  field :userid_messages,type: Array, default: []
  field :reason_for_invalidating,type: String

  attr_accessor :action, :message
  index({ email_address: 1 })
  index({ userid: 1, person_role: 1 })
  index({ person_surname: 1, person_forename: 1 })
  index({syndicate: 1, active: 1}, {name: "syndicate_active"})
  index({person_role: 1}, {name: "person_role"})

  has_many :freereg1_csv_files, dependent: :restrict
  has_many :attic_files, dependent: :restrict
  has_many :assignments

  validates_presence_of :userid,:syndicate,:email_address, :person_role, :person_surname, :person_forename,
    :skill_level #,:transcription_agreement
  validates_format_of :email_address,:with => Devise::email_regexp
  validate :userid_and_email_address_does_not_exist, on: :create
  validate :email_address_does_not_exist, on: :update

  before_create :add_lower_case_userid,:capitalize_forename, :captilaize_surname
  after_create :save_to_refinery
  before_save :capitalize_forename, :captilaize_surname
  after_update :update_refinery
  before_destroy :delete_refinery_user_and_userid_folder

  class << self
    def syndicate(syndicate)
      where(:syndicate => syndicate)
    end
    def userid(userid)
      where(:userid => userid)
    end
    def id(userid)
      where(:id => userid)
    end
    def role(role)
      where(:person_role => role)
    end
    def active(active)
      where(:active => active)
    end
    def reason(reason)
      where(:disabled_reason_standard => reason)
    end
    def email_address_valid
      where(:email_address_valid => true)
    end
  end

  def remove_checked_messages(msg_id)
    self.reload
    return if !(self.userid_messages.include? msg_id)
    userid_msgs = self.userid_messages
    userid_msgs = userid_msgs - [msg_id]
    self.update_attribute(:userid_messages, userid_msgs) if userid_msgs.length != self.userid_messages.length
  end

  def count_not_checked_messages
    self.reload
    userid_msgs = self.userid_messages
    return 0 if userid_msgs.length == 0
    self.userid_messages.each do |msg_id|
      msg = Message.id(msg_id.to_s).first
      if msg.nil?
        userid_msgs = userid_msgs - [msg_id]
      end
    end
    self.update_attribute(:userid_messages, userid_msgs) if userid_msgs.length != self.userid_messages.length
    self.userid_messages.length
  end


  def self.get_active_userids_for_display(syndicate)
    @userids = UseridDetail.where(:active => true).all.order_by(userid_lower_case: 1) if syndicate == 'all'
    @userids = UseridDetail.where(:syndicate => syndicate, :active => true).all.order_by(userid_lower_case: 1) unless syndicate == 'all'
    @userids
  end

  def self.get_emails_for_selection(syndicate)
    users = UseridDetail.all.order_by(email_address: 1) if syndicate == 'all'
    users = UseridDetail.where(:syndicate => syndicate).all.order_by(email_address: 1) unless syndicate == 'all'
    @userids = Array.new
    @userids << ''
    users.each do |user|
      @userids << user.email_address
    end
    return @userids
  end

  def self.get_names_for_selection(syndicate)
    users = UseridDetail.all.order_by(person_surname: 1) if syndicate == 'all'
    users = UseridDetail.where(:syndicate => syndicate).all.order_by(person_surname: 1) unless syndicate == 'all'
    @userids = Array.new
    @userids << ''
    users.each do |user|
      name = ""
      name = user.person_surname + ":" + user.person_forename unless user.person_surname.nil?
      @userids << name
    end
    return @userids
  end

  def self.get_userids_for_display(syndicate)
    @userids  = UseridDetail.all.order_by(userid_lower_case: 1) if syndicate == 'all'
    @userids = UseridDetail.syndicate(syndicate).all.order_by(userid_lower_case: 1) unless syndicate == 'all'
    @userids
  end

  def self.get_userids_for_selection(syndicate)
    users = UseridDetail.all.order_by(userid_lower_case: 1) if syndicate == 'all'
    users = UseridDetail.where(:syndicate => syndicate).all.order_by(userid_lower_case: 1) unless syndicate == 'all'
    userids = Array.new
    users.each do |user|
      userids << user.userid
    end
    return userids
  end

  def add_fields(type,syndicate)
    self.syndicate = syndicate if self.syndicate.nil?
    self.userid = self.userid.strip unless self.userid.nil?
    self.sign_up_date =  DateTime.now
    self.active = true
    case
    when type == 'Register Researcher'
      self.person_role = 'researcher'
      self.syndicate = 'Researcher'
    when type == 'Register as Transcriber'
      self.person_role = 'transcriber'
    when type == 'Technical Registration'
      self.active  = false
      self.person_role = 'technical'
      self.syndicate = 'Technical'
    end
    password = Devise::Encryptable::Encryptors::Freereg.digest('temppasshope',nil,nil,nil)
    self.password = password
    self.password_confirmation = password
    self.email_address_last_confirmned = self.sign_up_date
    self.email_address_valid= true
    self.email_address_last_confirmned = Time.new
  end

  def add_lower_case_userid
    self[:userid_lower_case] = self[:userid].downcase
  end

  def capitalize_forename
    self.person_forename = self.person_forename.downcase.titleize
  end

  def captilaize_surname
    self.person_surname = self.person_surname.downcase.titleize
  end

  def changed_syndicate?(new_syndicate)
    new_syndicate.present? && self.syndicate != new_syndicate ? change = true : change = false
    change
  end

  def changed_email?(new_email)
    new_email.present? && self.email_address != new_email ? change = true : change = false
    change
  end

  def check_exists_in_refinery
    refinery_user = Refinery::Authentication::Devise::User.where(:username => self.userid).first
    if refinery_user.nil?
      return[false,"There is no refinery entry"]
    else
      return[true]
    end
  end

  def compute_records
    count = 0
    self.freereg1_csv_files.each do |file|
      count = count + file.records.to_i
    end
    count
  end

  def delete_refinery_user_and_userid_folder
    refinery_user = Refinery::Authentication::Devise::User.where(:username => self.userid).first
    refinery_user.destroy unless refinery_user.nil?
    details_dir = File.join(Rails.application.config.datafiles,self.userid)
    FileUtils.rmdir(details_dir) if File.file?(details_dir)
  end

  def email_address_does_not_exist
    if self.changed.include?('email_address')
      errors.add(:email_address, "Userid email already exists on change") if
      UseridDetail.where(:email_address => self[:email_address]).exists?  && (self.userid != Refinery::Authentication::Devise::User.where(:username => self[:userid]))
      errors.add(:email_address, "Refinery email already exists on change") if
      Refinery::Authentication::Devise::User.where(:email => self[:email_address]).exists? && (self.userid != Refinery::Authentication::Devise::User.where(:username => self[:userid]))
    end
  end

  def finish_creation_setup
    UserMailer.notification_of_transcriber_creation(self).deliver_now
  end

  def finish_researcher_creation_setup
    UserMailer.notification_of_researcher_registration(self).deliver_now
  end
  def finish_transcriber_creation_setup
    self.update_attribute(:email_address_last_confirmned, Time.now)
    UserMailer.notification_of_transcriber_registration(self).deliver_now
  end
  def finish_technical_creation_setup
    UserMailer.notification_of_technical_registration(self).deliver_now
  end

  def has_files?
    value = false
    value = true if Freereg1CsvFile.where(:userid => self.userid).exists?
    value
  end

  def need_to_confirm_email_address?
    result = false
    @user = UseridDetail.userid(self.userid).first
    @user.email_address_last_confirmned.blank? ? last_date = @user.sign_up_date : last_date = @user.email_address_last_confirmned
    result = true if !@user.email_address_valid || (last_date + FreeregOptionsConstants::CONFIRM_EMAIL_ADDRESS.days < Time.now)
    return result
  end



  def remember_search(search_query)
    self.search_queries << search_query
  end

  def save_to_attic
    #to-do unix permissions
    user = self
    details_dir = File.join(Rails.application.config.datafiles,user.userid)
    details_file = File.join(details_dir,".uDetails")
    newdir = File.join(details_dir,'.attic')
    Dir.mkdir(newdir) unless Dir.exists?(newdir)
    renamed_file = (details_file + "." + (Time.now.to_i).to_s).to_s
    File.rename(details_file,renamed_file)
    FileUtils.mv(renamed_file,newdir)
  end

  def save_to_refinery
    #avoid looping on password changes
    u = Refinery::Authentication::Devise::User.where(:username => self.userid).first
    if u.nil?
      u = Refinery::Authentication::Devise::User.new
    end
    u.username = self.userid
    u.email = self.email_address
    u.password = 'Password' # no-op
    u.password_confirmation = 'Password' # no-op
    u.encrypted_password = self.password # actual encrypted password
    u.reset_password_token = u.generate_reset_password_token!
    u.reset_password_sent_at =  Time.now
    u.userid_detail_id = self.id.to_s
    u.add_role('Refinery')
    u.add_role('Superuser') if (self.active && self.person_role == 'technical') || self.person_role =='system_administrator'
    u.add_role('CountyPages') if (self.active &&  self.person_role =='county_coordinator')
    u.save
  end

  def update_refinery
    u = Refinery::Authentication::Devise::User.where(:username => self.userid).first
    unless u.nil?
      u.email = self.email_address
      u.userid_detail_id = self.id.to_s
      u.add_role('Refinery')
      u.add_role('Superuser') if (self.active && self.person_role == 'technical') || self.person_role =='system_administrator'
      u.add_role('CountyPages') if (self.active &&  self.person_role =='county_coordinator')
      u.save
    end
  end

  def userid_and_email_address_does_not_exist
    errors.add(:userid, "Userid Already exists") if UseridDetail.where(:userid => self[:userid]).exists?
    errors.add(:userid, "Refinery User Already exists") if Refinery::Authentication::Devise::User.where(:username => self[:userid]).exists?
    errors.add(:email_address, "Userid email already exists") if UseridDetail.where(:email_address => self[:email_address]).exists?
    errors.add(:email_address, "Refinery email already exists") if Refinery::Authentication::Devise::User.where(:email => self[:email_address]).exists?
  end

  def write_userid_file
    user = self
    details_dir = File.join(Rails.application.config.datafiles,user.userid)
    Dir.mkdir(details_dir)  unless Dir.exist?(details_dir)
    details_file = File.join(details_dir,".uDetails")
    if File.file?(details_file)
      save_to_attic
    end
    #we do not need a udetails file in the change set
    details = File.new(details_file, "w")
    details.puts "Surname:#{user.person_surname}"
    details.puts "UserID:#{user.userid}"
    details.puts "EmailID:#{user.email_address}"
    details.puts "Password:#{user.password}"
    details.puts "GivenName:#{user.person_forename}"
    details.puts "Country:#{user.address}"
    details.puts "SyndicateID:#{ChapmanCode.values_at(user.syndicate)}"
    details.puts "SyndicateName:#{user.syndicate}"
    details.puts "SignUpDate:#{user.sign_up_date}"
    details.puts "Person:#{user.person_role}"
    unless user.active
      details.puts "DisabledDate:#{user.disabled_date}"
      details.puts "DisabledReason:#{user.disabled_reason}"
      details.puts "Active:0"
      details.puts "Disabled:1"
    else
      details.puts "Active:1"
      details.puts "Disabled:0"
    end
    details.close
  end

  def list_incomplete_registrations current_user, current_syndicate
    if current_syndicate == 'all'
      @users = list_all_users
    else
      @users = get_users(current_syndicate)
    end
    filter_users
  end

  def full_name
    "#{self.person_forename} #{self.person_surname}"
  end
  
  def registration_completed user
    user.password != registered_password
  end

  def self.transcription_agreement_accepted(user_id)
    user = self.userid(user_id).first
    user.transcription_agreement
  end

  private

  def filter_users
    @incompleted_registration_users = Array.new
    @users.each { |user|
      next if registration_completed(user)
      @incompleted_registration_users << user
    }    
    @incompleted_registration_users
  end

  def registered_password
    Devise::Encryptable::Encryptors::Freereg.digest('temppasshope',nil,nil,nil)
  end

  def list_all_users
    self.class.only(:_id, :userid, :password, :person_forename, :person_surname, :email_address, :syndicate)
  end

  def get_users(current_syndicate)
    Syndicate.get_users_for_syndicate(current_syndicate)
  end

end #end class
