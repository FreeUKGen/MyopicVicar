class UseridDetail
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short

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
  field :number_of_files, type: Integer, default: 0
  field :number_of_records, type: Integer, default: 0
  field :sign_up_date, type: DateTime
  field :disabled_date, type: DateTime
  field :disabled_reason, type: String
  field :person_role, type: String, default: 'researcher'
  field :syndicate_groups, type: Array
  field :county_groups, type: Array
  field :country_groups, type: Array
  field :digest, type: String, default: nil
  field :skill_notes, type: String
  field :transcription_agreement, type: Boolean
  field :technical_agreement, type: Boolean
  field :research_agreement, type: Boolean

  index({ email_address: 1 })
  index({ userid: 1, system_administrator: 1 })
  index({ userid: 1, data_manager: 1 })
  index({ userid: 1, syndicate_coordinator: 1 })
  index({ userid: 1, county_coordinator: 1 })
  index({ userid: 1, country_coordinator: 1 })
  index({ userid: 1, syndicate: 1 })
  index({ userid: 1, chapman_code: 1 })
  index({ userid: 1, volunteer_coordinator: 1 })
  scope :syndicate, ->(syndicate) { where(:syndicate => syndicate) }
  attr_protected
  #attr_accessible :email_address, email_address_confirm, :userid,:syndicate,:person_surname,:person_forename,:address,:telephone_number,:skill_level, :person_role, :sig_up_date

  has_many :search_queries

  validates_presence_of :userid, :email_address, :person_role
  validates :email_address,:format => {:with => /^[^@][\w\+.-]+@[\w.-]+[.][a-z]{2,4}$/i}
  validate :userid_and_email_address_does_not_exist, on: :create
  validate :email_address_does_not_exist, on: :update

  before_create :add_lower_case_userid

  after_create :save_to_refinery
  after_update :update_refinery

  before_destroy :delete_refinery_user_and_userid_folder



  def remember_search(search_query)
    self.search_queries << search_query
  end

  def write_userid_file
    user = self
    details_dir = File.join(Rails.application.config.datafiles,user.userid)
    Dir.mkdir(details_dir)  unless Dir.exists?(details_dir)
    details_file = File.join(details_dir,".uDetails")
    if File.file?(details_file)
      save_to_attic
    end
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

  def save_to_refinery
    #avoid looping on password changes
    u = Refinery::User.where(:username => self.userid).first
    if u.nil?
      u = Refinery::User.new
    end
    u.username = self.userid
    u.email = self.email_address
    u.password = 'Password' # no-op
    u.password_confirmation = 'Password' # no-op
    u.encrypted_password = self.password # actual encrypted password
    u.reset_password_token= Refinery::User.reset_password_token
    u.reset_password_sent_at = Time.now
    u.userid_detail_id = self.id.to_s
    u.add_role('Refinery')
    u.add_role('Superuser') if (self.active && self.person_role == 'technical') || self.person_role =='system_administrator'
    u.add_role('CountyPages') if (self.active &&  self.person_role =='county_coordinator')
    u.save
  end

  def update_refinery
    u = Refinery::User.where(:username => self.userid).first
    unless u.nil?
      u.email = self.email_address
      u.userid_detail_id = self.id.to_s
      u.add_role('Refinery')
      u.add_role('Superuser') if (self.active && self.person_role == 'technical') || self.person_role =='system_administrator'
      u.add_role('CountyPages') if (self.active &&  self.person_role =='county_coordinator')
      u.save
    end
  end

  def send_invitation_to_create_password
    type = self.person_role
    UserMailer.invitation_to_register_researcher(self).deliver if type == 'researcher'
    UserMailer.invitation_to_register_transcriber(self).deliver if type == 'transcriber'
    UserMailer.invitation_to_register_technical(self).deliver if type == 'technical'
  end

  def send_invitation_to_reset_password
    UserMailer.invitation_to_reset_password(self).deliver

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

  def userid_and_email_address_does_not_exist
    errors.add(:userid, "Userid Already exits") if UseridDetail.where(:userid => self[:userid]).exists?
    errors.add(:userid, "Refinery User Already exits") if Refinery::User.where(:username => self[:userid]).exists?
    unless self[:transcription_agreement].nil? # deals with off line updating
      errors.add(:transcription_agreement, "Must be accepted") unless self[:transcription_agreement] == true
    end

    errors.add(:email_address, "Userid email already exits") if UseridDetail.where(:email_address => self[:email_address]).exists?
    errors.add(:email_address, "Refinery email already exits") if Refinery::User.where(:email => self[:email_address]).exists?

  end

  def email_address_does_not_exist
    if self.changed.include?('email_address')
      errors.add(:email_address, "Userid email already exits on change") if
      UseridDetail.where(:email_address => self[:email_address]).exists?  && (self.userid != Refinery::User.where(:username => self[:userid]))
      errors.add(:email_address, "Refinery email already exits on change") if
      Refinery::User.where(:email => self[:email_address]).exists? && (self.userid != Refinery::User.where(:username => self[:userid]))
    end
  end

  def add_lower_case_userid
    self[:userid_lower_case] = self[:userid].downcase
  end

  def finish_creation_setup
    UserMailer.notification_of_transcriber_creation(self).deliver
  end

  def finish_researcher_creation_setup
    UserMailer.notification_of_researcher_registration(self).deliver
  end
  def finish_transcriber_creation_setup
    UserMailer.notification_of_transcriber_registration(self).deliver
  end
  def finish_technical_creation_setup
    UserMailer.notification_of_technical_registration(self).deliver
  end

  def add_fields(type)
    self.sign_up_date =  DateTime.now
    self.active = true
    case
    when type == 'Register Researcher'
      self.person_role = 'researcher'
      self.syndicate = 'Researcher'
    when type == 'Register Transcriber'
      self.person_role = 'transcriber'
    when type == 'Technical Registration'
      self.active  = false
      self.person_role = 'technical'
      self.syndicate = 'Technical'
    end
    password = Devise::Encryptable::Encryptors::Freereg.digest('temppasshope',nil,nil,nil)
    self.password = password
    self.password_confirmation = password
    self.userid = self.userid.downcase
  end

  def self.get_userids_for_display(syndicate,page)
    users = UseridDetail.all.order_by(userid_lower_case: 1) if syndicate == 'all'
    users = UseridDetail.where(:syndicate => syndicate).all.order_by(userid_lower_case: 1) unless syndicate == 'all'
    @userids = Array.new
    users.each do |user|
      @userids << user
    end
    @userids = Kaminari.paginate_array(@userids).page(page)
  end

  def self.get_active_userids_for_display(syndicate,page)
    users = UseridDetail.where(:active => true).all.order_by(userid_lower_case: 1) if syndicate == 'all'
    users = UseridDetail.where(:syndicate => syndicate, :active => true).all.order_by(userid_lower_case: 1) unless syndicate == 'all'
    @userids = Array.new
    users.each do |user|
      @userids << user
    end
    @userids = Kaminari.paginate_array(@userids).page(page)
  end

  def self.get_userids_for_selection(syndicate)
    users = UseridDetail.all.order_by(userid_lower_case: 1) if syndicate == 'all'
    users = UseridDetail.where(:syndicate => syndicate).all.order_by(userid_lower_case: 1) unless syndicate == 'all'
    @userids = Array.new
    users.each do |user|
      @userids << user.userid
    end
    return @userids
  end

  def self.get_emails_for_selection(syndicate)
    users = UseridDetail.all.order_by(email_address: 1) if syndicate == 'all'
    users = UseridDetail.where(:syndicate => syndicate).all.order_by(email_address: 1) unless syndicate == 'all'
    @userids = Array.new
    users.each do |user|
      @userids << user.email_address
    end
    return @userids
  end
  def self.get_names_for_selection(syndicate)
    users = UseridDetail.all.order_by(person_surname: 1) if syndicate == 'all'
    users = UseridDetail.where(:syndicate => syndicate).all.order_by(person_surname: 1) unless syndicate == 'all'
    @userids = Array.new
    users.each do |user|
      name = ""
      name = user.person_surname + ":" + user.person_forename unless user.person_surname.nil?
      @userids << name
    end
    return @userids
  end
  def delete_refinery_user_and_userid_folder
    refinery_user = Refinery::User.where(:username => self.userid).first
    refinery_user.destroy unless refinery_user.nil?
    details_dir = File.join(Rails.application.config.datafiles,self.userid)
    FileUtils.rmdir(details_dir) if File.file?(details_dir)
  end

end #end class
