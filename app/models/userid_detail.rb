class UseridDetail
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short

  require 'freereg_options_constants'

  field :userid, type: String
  field :userid_lower_case, type: String
  field :syndicate, type: String
  field :syndicate_coordinator, type: String
  field :submitter_number, type: String
  field :person_surname, type: String
  field :person_forename, type: String
  field :email_address, type: String
  field :alternate_email_address, type: String
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
  field :skill_notes, type: String # only planned to be used for technical registrations
  field :transcription_agreement, type: Boolean, default: false
  field :technical_agreement, type: Boolean, default: false
  field :research_agreement, type: Boolean, default: false
  field :email_address_valid, type: Boolean, default: true
  field :email_address_last_confirmned, type: DateTime
  field :no_processing_messages, type: Boolean, default: false
  field :userid_messages,type: Array, default: []
  field :userid_feedback_replies,type: Hash, default: {}
  field :reason_for_invalidating,type: String
  field :new_transcription_agreement, type: String, default: "Unknown"
  field :email_address_validity_change_message, type: Array, default: []
  field :secondary_role, type: Array, default: []
  field :do_not_acknowledge_me, type: Boolean
  field :acknowledge_with_pseudo_name, type: Boolean
  field :pseudo_name, type: String
  field :saved_entry, type: Array, default: []
  # Note if you add or change fields you may need to update the display and edit field order in /lib/freereg_options_constants

  attr_accessor :action, :message, :volunteer_induction_handbook, :code_of_conduct, :volunteer_policy
  index({ email_address: 1 })
  index({ userid: 1, person_role: 1 })
  index({ person_surname: 1, person_forename: 1 })
  index({syndicate: 1, active: 1}, {name: "syndicate_active"})
  index({person_role: 1}, {name: "person_role"})

  has_many :freereg1_csv_files, dependent: :restrict_with_error
  has_many :attic_files, dependent: :restrict_with_error
  has_many :assignments
  has_many :saved_searches

  validates_presence_of :userid,:syndicate,:email_address, :person_role, :person_surname, :person_forename,
    :skill_level #,:new_transcription_agreement
  validates_format_of :email_address,:with => Devise::email_regexp
  validate :userid_and_email_address_does_not_exist, :transcription_agreement_must_accepted, on: :create
  validate :email_address_does_not_exist, on: :update
  validate :active_with_inactive_reason, on: :update
  validates :volunteer_induction_handbook, :code_of_conduct, :volunteer_policy, acceptance: true

  before_create :add_lower_case_userid,:capitalize_forename, :captilaize_surname, :remove_secondary_role_blank_entries, :transcription_agreement_value_change
  after_create :save_to_refinery
  before_save :capitalize_forename, :captilaize_surname, :remove_secondary_role_blank_entries
  #after_update :update_refinery
  before_destroy :delete_refinery_user_and_userid_folder

  @current_year = DateTime.now.year
  @old_date = "2017/10/17"
  @new_date = DateTime.new(@current_year, 01, 01)
  @users_count = UseridDetail.count
  EVENT_YEAR_ONLY = 589

  scope :users_marked_active, ->{ where(active: true) }
  scope :users_accepted_new_transcription_agreement, ->{ where(new_transcription_agreement: "Accepted") }
  scope :new_users, ->{ where(sign_up_date: {'$gte': @new_date }) }
  scope :old_users, ->{ where(sign_up_date: {'$lt': @new_date }) }
  scope :user_role_transcriber, -> { where(person_role: 'transcriber') }

  class << self
    def syndicate(syndicate)
      where(:syndicate => syndicate)
    end

    def syndicate_coordinator(syndicate_coordinator)
      where(:syndicate_coordinator => syndicate_coordinator)
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

    def secondary(role)
      where(:secondary_role => role)
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

    def transcription_agreement(transcription_agreement)
      where(:transcription_agreement => transcription_agreement)
    end

    def new_transcription_agreement(new_transcription_agreement)
      if new_transcription_agreement[0] == 'All'
        where(new_transcription_agreement: { '$in': SentMessage::ACTUAL_STATUS_MESSAGES })
      elsif new_transcription_agreement.length == 1
        where(new_transcription_agreement: new_transcription_agreement[0])
      else
        where(new_transcription_agreement: { '$in': new_transcription_agreement })
      end
    end

    def can_we_acknowledge_the_transcriber(userid)
      answer = false
      transcribed_by = nil
      if userid.present? && userid.do_not_acknowledge_me.blank?
        answer = true
        if userid.acknowledge_with_pseudo_name
          transcribed_by = userid.pseudo_name
        else
          transcribed_by = userid.person_forename
          transcribed_by = transcribed_by.nil? ? userid.person_surname : transcribed_by = transcribed_by + ' ' + userid.person_surname
        end
      end
      [answer, transcribed_by]
    end

    def create_friendly_from_email(userid)
      user = UseridDetail.userid(userid).first
      if user.present?
        friendly_email = "#{user.person_forename} #{user.person_surname} <#{user.email_address}>"
      elsif MyopicVicar::Application.config.template_set == 'freereg'
        friendly_email = 'FreeREG Servant <freereg-contacts@freereg.org.uk>'
      elsif MyopicVicar::Application.config.template_set == 'freecen'
        friendly_email = 'FreeCEN Servant <freecen-contacts@freecen.org.uk>'
      end
      friendly_email
    end


    def uploaded_freecen_file(users, transcribers)
      uploaded = []
      FreecenCsvFile.where(:userid.exists => true).each do |file|
        uploaded << file.userid
      end
      uploaded = uploaded.uniq
      total_uploading_users = uploaded.length
      total_uploading_transcribers = 0
      uploaded.each do |user|
        who = UseridDetail.find_by(userid: user)
        total_uploading_transcribers += 1 if who.person_role == 'transcriber'
      end
      users_not_uploading = users - total_uploading_users
      transcribers_not_uploading = transcribers - total_uploading_transcribers
      [users_not_uploading, transcribers_not_uploading, total_uploading_users, total_uploading_transcribers]
    end

    def modern_freecen_active
      users = 0
      transcribers = 0
      start = Time.new(2020, 12, 1).to_i
      Refinery::Authentication::Devise::User.all.each do |user|
        next if Time.parse(user.updated_at.to_s).to_i < start

        userid = UseridDetail.find_by(_id: user.userid_detail_id)
        users += 1 if userid.present?
        transcribers += 1 if userid.present? && userid.person_role == 'transcriber'
      end
      [users, transcribers]
    end
  end


  # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Instance Methods

  def add_fields(type, syndicate)
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
    #self.new_transcription_agreement = "Unknown"
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

  def delete_feedback
    self.userid_feedback_replies.each do |feedback_id, message_id|
      next unless message_id.empty?
      feedback = Feedback.id(feedback_id).first
      if feedback.nil?
        @userid_feedback_msgs.except!(feedback_id)
      end
    end
  end

  def does_not_have_original_message?(message)
    userid_messages.include?(message.source_message_id) ? answer = false : answer = true
    answer
  end

  def feedback_without_replies
    self.update_userid_feedbacks
    @feedbacks_with_no_reply = self.userid_feedback_replies.keys.select do |id|
      self.userid_feedback_replies[id].blank?
    end
  end

  def feedback_with_replies
    self.update_userid_feedbacks
    @feedbacks_with_no_reply = self.userid_feedback_replies.keys.reject do |id|
      self.userid_feedback_replies[id].blank?
    end
  end

  def has_original_message?(message)
    userid_messages.include?(message.source_message_id) ? answer = true : answer = false
    answer
  end

  def meets_open_status_requirement?(open_data_status)
    return true if open_data_status[0] == 'All'

    open_data_status.each do |status|
      return true if new_transcription_agreement == status
    end
    false
  end

  def meets_reasons?(reasons)
    reasons.each do |reason|
      return true if disabled_reason == reason || disabled_reason_standard == reason
    end
    false
  end

  def self.look_up_id(userid)
    user = UseridDetail.userid(userid).first
  end

  def remove_checked_messages(msg_id)
    self.reload
    return if !(self.userid_messages.include? msg_id)
    userid_msgs = self.userid_messages
    userid_msgs = userid_msgs - [msg_id]
    self.update_attribute(:userid_messages, userid_msgs) if userid_msgs.length != self.userid_messages.length
  end

  def remove_deleted_messages(date)
    removal = []
    userid_msgs = userid_messages
    userid_msgs.each do |message_id|
      removal << message_id if Message.should_be_removed_from_userid?(message_id, date)
    end
    removal.each do |message|
      userid_msgs = userid_msgs - [message]
    end
    update(userid_messages: userid_msgs) if userid_msgs.length != userid_messages.length
  end

  def update_userid_feedbacks
    self.reload
    update_feedback_replies
    @userid_feedback_msgs = self.userid_feedback_replies
    return {} if @userid_feedback_msgs.empty?
    delete_feedback
    self.userid_feedback_replies.replace(@userid_feedback_msgs) if @userid_feedback_msgs.length != self.userid_feedback_replies.length
    self.update_attribute(:userid_feedback_replies, self.userid_feedback_replies)
  end

  def update_feedback_replies
    self.userid_feedback_replies.each do |key, value|
      next if value.blank?
      @existing_messages = value.delete_if do |v|
        Message.where(id: v).blank?
      end
      self.userid_feedback_replies.store(key, @existing_messages) if value.length != @existing_messages
    end
  end


  def self.userids_active_for_display(syndicate)
    @userids = UseridDetail.where(:active => true).all.order_by(userid_lower_case: 1) if syndicate == 'all'
    @userids = UseridDetail.where(:syndicate => syndicate, :active => true).all.order_by(userid_lower_case: 1) unless syndicate == 'all'
    @userids
  end

  def self.userids_for_display(syndicate)
    @userids = UseridDetail.all.order_by(userid_lower_case: 1) if syndicate == 'all'
    @userids = UseridDetail.syndicate(syndicate).all.order_by(userid_lower_case: 1) unless syndicate == 'all'
    @userids
  end

  def self.userids_agreement_signed_for_display(syndicate)
    @userids = UseridDetail.where(active: true, new_transcription_agreement: 'Accepted').all.order_by(userid_lower_case: 1) if syndicate == 'all'
    @userids = UseridDetail.where(syndicate: syndicate, active: true, new_transcription_agreement: 'Accepted').all.order_by(userid_lower_case: 1) unless syndicate == 'all'
    @userids
  end

  def self.userids_agreement_not_signed_for_display(syndicate)
    @userids = UseridDetail.where(:active => true, :new_transcription_agreement.ne => 'Accepted').all.order_by(userid_lower_case: 1) if syndicate == 'all'
    @userids = UseridDetail.where(:syndicate => syndicate, :active => true, :new_transcription_agreement.ne => 'Accepted').all.order_by(userid_lower_case: 1) unless syndicate == 'all'
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
    return @userids.sort_by(&:downcase)
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
    return @userids.sort_by(&:downcase)
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
    return if MyopicVicar::Application.config.template_set == 'freecen'
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
    errors.add(:userid, "Userid Already exists") if UseridDetail.where(:userid => self[:userid]).exists?
    errors.add(:userid, "Refinery User Already exists") if Refinery::User.where(:username => self[:userid]).exists?
    errors.add(:email_address, "Userid email already exists") if UseridDetail.where(:email_address => self[:email_address]).exists?
    errors.add(:email_address, "Refinery email already exists") if Refinery::User.where(:email => self[:email_address]).exists?
  end

  #def userid_and_email_address_does_not_exist
  # errors.add(:userid, "Userid Already exists") if UseridDetail.where(:userid => self[:userid]).exists?
  #errors.add(:userid, "Refinery User Already exists") if Refinery::Authentication::Devise::User.where(:username => self[:userid]).exists?
  #errors.add(:email_address, "Userid email already exists") if UseridDetail.where(:email_address => self[:email_address]).exists?
  #errors.add(:email_address, "Refinery email already exists") if Refinery::Authentication::Devise::User.where(:email => self[:email_address]).exists?
  #end

  def self.get_userids_for_selection(syndicate)
    users = UseridDetail.all.order_by(userid_lower_case: 1) if syndicate == 'all'
    users = UseridDetail.where(:syndicate => syndicate).all.order_by(userid_lower_case: 1) unless syndicate == 'all'
    userids = Array.new
    users.each do |user|
      userids << user.userid
    end
    userids
  end

  def self.get_userids_for_display(syndicate)
    users = UseridDetail.all.order_by(userid_lower_case: 1) if syndicate == 'all'
    users = UseridDetail.where(:syndicate => syndicate).all.order_by(userid_lower_case: 1) unless syndicate == 'all'
    users
  end



  def remove_secondary_role_blank_entries
    secondary_role = self.secondary_role
    if secondary_role.include? ""
      secondary_role.delete("")
    end
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
    refinery_user = User.where(:username => self.userid).first
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
    refinery_user = User.where(:username => self.userid).first
    refinery_user.destroy unless refinery_user.nil?
    details_dir = File.join(Rails.application.config.datafiles,self.userid)
    return if MyopicVicar::Application.config.template_set == 'freecen'
    FileUtils.rmdir(details_dir) if File.file?(details_dir)
  end

  def email_address_does_not_exist
    if self.changed.include?('email_address')
      errors.add(:email_address, "Userid email already exists on change") if
      UseridDetail.where(:email_address => self[:email_address]).exists?  && (self.userid != User.where(:username => self[:userid]))
      errors.add(:email_address, "Refinery email already exists on change") if
      Refinery::Authentication::Devise::User.where(:email => self[:email_address]).exists? && (self.userid != User.where(:username => self[:userid]))
    end
  end

  def active_with_inactive_reason
    errors.add(:active, 'box must be unchecked if Reason for making inactive specified') if active && disabled_reason_standard.present?
  end

  def self.userid_does_not_exist
    if self.changed.include?('userid')
      errors.add(:base, "Userid Already exists") if UseridDetail.where(:userid => self[:userid]).exists?
      errors.add(:base, "User Already exists") if User.where(:username => self[:userid]).exists?
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

  def json_of_my_profile
    json_of_my_profile = Hash.new
    fields = FreeregOptionsConstants::USERID_DETAILS_MYOWN_DISPLAY
    fields.each do |field|
      self[field].blank? ? json_of_my_profile[field.to_sym] = nil : json_of_my_profile[field.to_sym]  = self[field]
    end
    json_of_my_profile
  end

  def need_to_confirm_email_address?
    result = false
    @user = UseridDetail.find_by(userid: userid)
    last_date = @user.email_address_last_confirmned.blank? ? @user.sign_up_date : @user.email_address_last_confirmned
    result = true if !@user.email_address_valid || (last_date + FreeregOptionsConstants::CONFIRM_EMAIL_ADDRESS.days < Time.now)
    result
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
    u = User.where(:username => self.userid).first
    if u.nil?
      u = User.new
    end
    raw, hashed = Devise.token_generator.generate(User, :reset_password_token)
    u.username = self.userid
    u.email = self.email_address
    u.password = 'Password' # no-op
    u.password_confirmation = 'Password' # no-op
    u.encrypted_password = self.password # actual encrypted password
    u.reset_password_token = hashed
    u.reset_password_sent_at =  Time.now
    u.userid_detail_id = self.id.to_s
    #u.add_role('Refinery')
    #u.add_role('Superuser') if (self.active && self.person_role == 'technical') || self.person_role =='system_administrator'
    #u.add_role('CountyPages') if (self.active &&  self.person_role =='county_coordinator')
    u.save!
  end

  def update_refinery
    u = User.where(:username => self.userid).first
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
    errors.add(:userid, "Refinery User Already exists") if User.where(:username => self[:userid]).exists?
    errors.add(:email_address, "Userid email already exists") if UseridDetail.where(:email_address => self[:email_address]).exists?
    errors.add(:email_address, "Refinery email already exists") if User.where(:email => self[:email_address]).exists?
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
    @users = get_users_by_syndicate(current_syndicate)
    filter_users
  end

  def full_name
    "#{self.person_forename} #{self.person_surname}"
  end

  def registration_completed user
    user.password != registered_password
  end

  def incomplete_registration_user_lists(current_syndicate, active)
    syndicate_users = get_users_by_syndicate(current_syndicate)
    if active.nil?
      @users = syndicate_users
    elsif active
      @users = syndicate_users.where(active: true)
    else
      @users = syndicate_users.where(active: false)
    end
    active_lists(get_user_ids)
  end

  def active_incomplete_registration_list
    @users = list_all_users
    active_incomplete_registrations = Array.new
    filter_users.each { |usr|
      next if !usr.active
      active_incomplete_registrations << usr.userid
    }
    active_incomplete_registrations
  end

  def active_lists(user_lists)
    original_stdout = STDOUT.clone
    file_name = "active_incomplete_registrations"
    ApplicationController.helpers.delete_file_if_exists(file_name)
    STDOUT.reopen(ApplicationController.helpers.new_file(file_name), "w")
    puts user_lists
    STDOUT.reopen(original_stdout)
    puts "Total number of ids: #{user_lists.count}"
  end

  def incomplete_user_registrations_count
    @users = list_all_users
    return filter_users.count
  end

  def incomplete_transcribers_registrations_count
    @users = UseridDetail.where(person_role: "transcriber")
    return filter_users.count
  end

  def self.return_percentage_all_existing_users_accepted_transcriber_agreement
    total_existing_users = old_users.count.to_f
    total_existing_users_accepted = old_users.users_accepted_new_transcription_agreement.count.to_f
    if total_existing_users == 0 || total_existing_users_accepted == 0
      return 0
    else
      return ((total_existing_users_accepted / total_existing_users) * 100).round(2)
    end
  end

  def self.return_percentage_all_existing_active_users_accepted_transcriber_agreement
    total_existing_active_users = users_marked_active.old_users.count.to_f
    total_existing_active_users_accepted = users_marked_active.old_users.users_accepted_new_transcription_agreement.count.to_f
    if total_existing_active_users == 0 || total_existing_active_users_accepted == 0
      return 0
    else
      return ((total_existing_active_users_accepted / total_existing_active_users) * 100).round(2)
    end
  end

  def self.number_of_transcribers_uploaded_file_recently(month)
    user_role_transcriber.where(last_upload: {'$gt': month.months.ago}).count
  end

  def self.return_percentage_all_users_accepted_transcriber_agreement
    total_users = @users_count.to_f
    total_users_accepted = users_accepted_new_transcription_agreement.count.to_f
    if total_users == 0 || total_users_accepted == 0
      return 0
    else
      return ((total_users_accepted / total_users) * 100).round(2)
    end
  end

  def self.return_percentage_total_records_by_transcribers
    total_records_all = return_total_records.to_f
    total_records_open_transcribers = return_total_transcriber_records.to_f
    if total_records_all == 0 || total_records_open_transcribers == 0
      return 0
    else
      return (total_records_open_transcribers / total_records_all) * 100
    end
  end

  def self.return_total_transcriber_records
    total_records = 0
    UseridDetail.where(person_role: 'transcriber', new_transcription_agreement: 'Accepted', number_of_records: { '$ne': 0 }).each do |count|
      total_records += count.number_of_records
    end
    total_records
  end

  def self.return_total_records
    total_records = 0
    UseridDetail.where(number_of_records: { '$ne': 0 }).each do |count|
      total_records += count.number_of_records
    end
    total_records
  end

  def get_saved_entries
    record_hash = self.saved_entry
    record_number = BestGuessHash.where(Hash: record_hash).pluck(:RecordNumber)
    BestGuess.where(RecordNumber: record_number)
  end

  def saved_entries_as_array
    record_hash = self.saved_entry
    record_number = BestGuessHash.where(Hash: record_hash).pluck(:RecordNumber)
    record_number
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
    self.class.only(:_id, :userid, :password, :person_forename, :person_surname, :email_address, :syndicate, :active)
  end

  def get_users_by_syndicate(current_syndicate)
    if current_syndicate == 'all'
      list_all_users
    else
      self.class.syndicate(current_syndicate)
    end
  end

  def get_user_ids
    filter_users.map{ |x| x[:userid] }
  end

  def transcription_agreement_must_accepted
    errors.add(:base, "Transcription agreement must be accepted") if self.new_transcription_agreement == "0"
  end

  def transcription_agreement_value_change
    if self.new_transcription_agreement == "1"
      self.new_transcription_agreement = 'Accepted'
    elsif self.new_transcription_agreement == 0
      self.new_transcription_agreement = 'Declined'
    end
  end
end #end class
