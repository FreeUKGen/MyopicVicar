class Contact
  include Mongoid::Document
  include Mongoid::Timestamps
  field :body, type: String
  field :contact_time, type: DateTime
  field :name, type: String
  field :email_address, type: String
  field :county, type: String
  field :session_id, type: String
  field :problem_page_url, type: String
  field :previous_page_url, type: String
  field :contact_type, type: String
  field :github_issue_url, type: String
  field :github_comment_url, type: String
  field :github_number, type: String
  field :session_data, type: Hash
  field :screenshot, type: String
  field :record_id, type: String
  field :entry_id, type: String
  field :line_id, type: String
  field :contact_name, type: String, default: nil  # this field is used as a span trap
  field :query, type: String
  field :selected_county, type: String # user-selected county to contact in FC2
  field :fc_individual_id, type: String
  field :identifier, type: String
  attr_accessor :action

  validates_presence_of :name, :email_address
  validates :email_address,:format => {:with => /^[^@][\w\+.-]+@[\w.-]+[.][a-z]{2,4}$/i}

  mount_uploader :screenshot, ScreenshotUploader

  before_create :url_check, :add_identifier

  class << self
    def id(id)
      where(:id => id)
    end
  end

  def url_check

    self.problem_page_url = "unknown" if self.problem_page_url.nil?
    self.previous_page_url = "unknown" if self.previous_page_url.nil?
  end

  def add_identifier
    self.identifier = Time.now.to_i - Time.gm(2015).to_i
  end

  def communicate
    case
    when  self.contact_type == 'Website Problem'
      self.communicate_website_problem
    when self.contact_type == 'Data Question'
      self.communicate_data_question
    when self.contact_type == 'Data Problem'
      self.communicate_data_problem
    when self.contact_type == 'Volunteering Question'
      self.communicate_volunteering
    when self.contact_type == 'General Comment'
      self.communicate_general
    when self.contact_type == "Thank you"
      self.communicate_publicity
    when self.contact_type == 'Genealogical Question'
      self.communicate_genealogical_question
    when self.contact_type == 'Enhancement Suggestion'
      self.communicate_enhancement_suggestion
    else
      self.communicate_general
    end
  end


  def communicate_website_problem
    ccs = Array.new
    selected_coord = get_coordinator_for_selected_county
    ccs << selected_coord.email_address unless selected_coord.nil?
    UseridDetail.where(:person_role => 'system_administrator').all.each do |person|
      ccs << person.email_address
    end
    cc = UseridDetail.where(:person_role => 'contacts_coordinator').first
    ccs << cc.email_address unless cc.nil?
    cc = UseridDetail.where(:person_role => 'project_manager').first
    ccs << cc.email_address unless cc.nil?
    cc = UseridDetail.where(:person_role => 'executive_director').first
    ccs << cc.email_address unless cc.nil?
    UserMailer.website(self,ccs).deliver
  end

  def communicate_data_question
    ccs = Array.new
    selected_coord = get_coordinator_for_selected_county
    ccs << selected_coord.email_address unless selected_coord.nil?
    UseridDetail.where(:person_role => 'data_manager').all.each do |person|
      ccs << person.email_address
    end
    UseridDetail.where(:person_role => 'system_administrator').all.each do |person|
      ccs << person.email_address
    end
    cc = UseridDetail.where(:person_role => 'contacts_coordinator').first
    ccs << cc.email_address unless cc.nil?
    UserMailer.datamanager_data_question(self,ccs).deliver
  end

  def communicate_data_problem
    ccs = Array.new
    selected_coord = get_coordinator_for_selected_county
    ccs << selected_coord.email_address unless selected_coord.nil?
    coordinator = self.get_coordinator if self.record_id.present?
    ccs << coordinator.email_address if coordinator.present?
    UseridDetail.where(:person_role => 'data_manager').all.each do |person|
      ccs << person.email_address
    end
   UseridDetail.where(:person_role => 'system_administrator').all.each do |person|
      ccs << person.email_address
    end
    cc = UseridDetail.where(:person_role => 'contacts_coordinator').first
    ccs << cc.email_address unless cc.nil?
    UserMailer.coordinator_data_problem(self,ccs).deliver
  end


  def communicate_publicity
    ccs = Array.new
    selected_coord = get_coordinator_for_selected_county
    ccs << selected_coord.email_address unless selected_coord.nil?
    UseridDetail.where(:person_role => 'publicity_coordinator').all.each do |person|
      ccs << person.email_address
    end
    cc = UseridDetail.where(:person_role => 'executive_director').first
    ccs << cc.email_address unless cc.nil?
    UseridDetail.where(:person_role => 'system_administrator').all.each do |person|
      ccs << person.email_address
    end
    cc = UseridDetail.where(:person_role => 'contacts_coordinator').first
    ccs << cc.email_address unless cc.nil?
    UserMailer.publicity(self,ccs).deliver
  end

  def communicate_genealogical_question
    ccs = Array.new
    selected_coord = get_coordinator_for_selected_county
    ccs << selected_coord.email_address unless selected_coord.nil?
    UseridDetail.where(:person_role => 'genealogy_coordinator').all.each do |person|
      ccs << person.email_address
    end
    UseridDetail.where(:person_role => 'contact_coordinator').all.each do |person|
      ccs << person.email_address
    end
    UseridDetail.where(:person_role => 'system_administrator').all.each do |person|
      ccs << person.email_address
    end
    UserMailer.genealogy(self,ccs).deliver
  end

  def communicate_enhancement_suggestion
    ccs = Array.new
    selected_coord = get_coordinator_for_selected_county
    ccs << selected_coord.email_address unless selected_coord.nil?
    UseridDetail.where(:person_role => 'project_manager').all.each do |person|
      ccs << person.email_address
    end
    cc = UseridDetail.where(:person_role => 'executive_director').first
    ccs << cc.email_address unless cc.nil?
    UseridDetail.where(:person_role => 'system_administrator').all.each do |person|
      ccs << person.email_address
    end
    cc = UseridDetail.where(:person_role => 'contacts_coordinator').first
    ccs << cc.email_address unless cc.nil?
    UserMailer.enhancement(self,ccs).deliver
  end

  def communicate_volunteering
    ccs = Array.new
    selected_coord = get_coordinator_for_selected_county
    ccs << selected_coord.email_address unless selected_coord.nil?
    UseridDetail.where(:person_role => 'volunteer_coordinator').all.each do |person|
      ccs << person.email_address
    end
    UseridDetail.where(:person_role => 'engagement_coordinator').all.each do |person|
      ccs << person.email_address
    end
    UseridDetail.where(:person_role => 'system_administrator').all.each do |person|
      ccs << person.email_address
    end
    cc = UseridDetail.where(:person_role => 'contacts_coordinator').first
    ccs << cc.email_address unless cc.nil?
    UserMailer.volunteer(self,ccs).deliver
  end

  def communicate_general
    ccs = Array.new
    selected_coord = get_coordinator_for_selected_county
    ccs << selected_coord.email_address unless selected_coord.nil?
    UseridDetail.where(:person_role => 'contacts_coordinator').all.each do |person|
      ccs << person.email_address unless person.nil?
    end
    UseridDetail.where(:person_role => 'system_administrator').all.each do |person|
      ccs << person.email_address
    end
    UserMailer.general(self,ccs).deliver
  end

  def get_coordinator
    if MyopicVicar::Application.config.template_set == 'freereg'
      entry = SearchRecord.find(self.record_id).freereg1_csv_entry
      record = Freereg1CsvEntry.find(entry)
      file = record.freereg1_csv_file
      county = file.county #this is chapman code
      coordinator = UseridDetail.where(:userid => County.where(:chapman_code => county).first.county_coordinator).first
    elsif MyopicVicar::Application.config.template_set == 'freecen'
      coord = nil
      rec_county = SearchRecord.find(self.record_id).chapman_code
      if rec_county.present?
        c = County.where(:chapman_code => rec_county).first
        return nil if c.nil?
        cc_id = c.county_coordinator
        coord = UseridDetail.where(:userid => cc_id).first unless cc_id.nil?
      end
      return coord
    end
  end

  # used by freecen if user selects to contact coordinator for a specific county
  def get_coordinator_for_selected_county
    return nil if MyopicVicar::Application.config.template_set != 'freecen'
    return nil if nil == self.selected_county || ''==self.selected_county
    c = County.where(:chapman_code => self.selected_county).first
    return nil if c.nil?
    cc_userid = c.county_coordinator
    coord = UseridDetail.where(:userid => cc_userid).first unless cc_userid.nil?
    coord
  end

  def github_issue
    appname = MyopicVicar::Application.config.freexxx_display_name.upcase
    if Contact.github_enabled
      Octokit.configure do |c|
        c.login = Rails.application.config.github_login
        c.password = Rails.application.config.github_password
      end
      response = Octokit.create_issue(Rails.application.config.github_repo, issue_title, issue_body, :labels => [])
      logger.info("#{appname}:GITHUB response: #{response}")
      logger.info(response.inspect)
      self.update_attributes(:github_issue_url => response[:html_url],:github_comment_url => response[:comments_url], :github_number => response[:number])
    else
      logger.error("#{appname}:Tried to create an issue, but Github integration is not enabled!")
    end
  end

  def self.github_enabled
    !Rails.application.config.github_password.blank?
  end

  def issue_title
    "#{identifier} #{contact_type} (#{name})"
  end

  def issue_body
    issue_body = ApplicationController.new.render_to_string(:partial => 'contacts/github_issue_body.txt', :locals => {:feedback => self})
    issue_body
  end

  def contact_screenshot_url
    return nil unless screenshot.present?
    cid=self._id.to_s unless self._id.nil?
    ss=File.basename(screenshot.to_s)
    MyopicVicar::Application.config.website + "/uploads/contact/screenshot/#{cid}/#{ss}"
  end

end
