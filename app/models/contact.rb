class Contact
  include Mongoid::Document
  include Mongoid::Timestamps
  field :body, type: String
  field :contact_time, type: DateTime
  field :name, type: String
  field :email_address, type: String
  field :session_id, type: String
  field :problem_page_url, type: String
  field :previous_page_url, type: String
  field :contact_type, type: String
  field :github_issue_url, type: String
  field :session_data, type: Hash
  field :screenshot, type: String
  field :record_id, type: String
  field :entry_id, type: String
  field :line_id, type: String
  field :contact_name, type: String, default: nil  # this field is used as a span trap
  field :query, type: String
  field :identifier, type: String
  
  validates_presence_of :name, :email_address
  validates :email_address,:format => {:with => /^[^@][\w\+.-]+@[\w.-]+[.][a-z]{2,4}$/i}

  mount_uploader :screenshot, ScreenshotUploader

  before_create :url_check, :add_identifier
  after_create :communicate
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
    set = Random.new(123456789)
    self.identifier = set.rand(10000000)  
  end

  def communicate
    case 
      when  self.contact_type == 'Website Problem'
        self.communicate_website_problem
      when self.contact_type == 'Data Question'
        self.communicate_data_question
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
    UseridDetail.where(:person_role => 'system_administrator').all.each do |person|
      ccs << person.email_address
    end
    cc = UseridDetail.where(:person_role => 'project_manager').first
    ccs << cc.email_address unless cc.nil?
    UserMailer.website(self,ccs).deliver    
  end 

  def communicate_data_question
    ccs = Array.new
    coordinator = contact.get_coordinator if self.record_id.present?
    ccs << coordinator.person_forename if self.record_id.present?
    UseridDetail.where(:person_role => 'data_manager').all.each do |person|
       ccs << person.person_forename
    end
    UserMailer.coordinator_data_question(self,ccs).deliver if coordinator.present?
    UserMailer.datamanger_data_question(self,ccs).deliver unless coordinator.present?
  end

  def communicate_publicity
    ccs = Array.new
    UseridDetail.where(:person_role => 'publicity_coordinator').all.each do |person|
      ccs << person.email_address
    end
    cc = UseridDetail.where(:person_role => 'executive_director').first
    ccs << cc.email_address unless cc.nil?
    UserMailer.publicity(self,ccs).deliver     
  end

  def communicate_genealogical_question
    ccs = Array.new
    UseridDetail.where(:person_role => 'genealogy_coordinator').all.each do |person|
      ccs << person.email_address
    end
    UseridDetail.where(:person_role => 'contact_coordinator').all.each do |person|
      ccs << person.email_address
    end
    UserMailer.genealogy(self,ccs).deliver        
  end

  def communicate_enhancement_suggestion
    ccs = Array.new
    UseridDetail.where(:person_role => 'project_manager').all.each do |person|
      ccs << person.email_address
    end
    cc = UseridDetail.userid('REGManager').first unless cc.nil?
    ccs << cc.email_address
    UserMailer.enhancement(self,ccs).deliver 
  end

  def communicate_volunteering
    ccs = Array.new
    UseridDetail.where(:person_role => 'volunteer_coordinator').all.each do |person|
      ccs << person.email_address
    end
    UseridDetail.where(:person_role => 'engagement_coordinator').all.each do |person|
      ccs << person.email_address
    end
    cc = UseridDetail.where(:userid => 'REGManager').first unless cc.nil?
    ccs << cc.email_address
    UserMailer.volunteer(self,ccs).deliver
  end

  def communicate_general
    ccs = Array.new
    UseridDetail.where(:person_role => 'contacts_coordinator').all.each do |person|
      ccs << person.email_address unless person.nil?
    end
    UserMailer.contact(self,ccs).deliver   
  end

  def get_coordinator
    entry = SearchRecord.find(self.record_id).freereg1_csv_entry
    record = Freereg1CsvEntry.find(entry)
    file = record.freereg1_csv_file
    county = file.county #this is chapman code
    coordinator = UseridDetail.where(:userid => County.where(:chapman_code => county).first.county_coordinator).first
  end

  def github_issue  
    if Contact.github_enabled
      Octokit.configure do |c|
        c.login = Rails.application.config.github_login
        c.password = Rails.application.config.github_password
      end
      response = Octokit.create_issue(Rails.application.config.github_repo, issue_title, issue_body, :labels => [])
      logger.info(response)
      self.github_issue_url = response[:html_url]
     
    else
      logger.error("Tried to create an issue, but Github integration is not enabled!")
    end
  end

  def self.github_enabled
    !Rails.application.config.github_password.blank?
  end

  def issue_title
    "#{contact_type} (#{name})"
  end

  def issue_body
    issue_body = ApplicationController.new.render_to_string(:partial => 'contacts/github_issue_body.txt', :locals => {:feedback => self})
    issue_body
  end

end
