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
  field :contact_county, type: String
  field :identifier, type: String
  validates_presence_of :name, :email_address
  validates :email_address,:format => {:with => /^[^@][\w\+.-]+@[\w.-]+[.][a-z]{2,4}$/i}

  mount_uploader :screenshot, ScreenshotUploader

  before_save :url_check
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

  def communicate
   
    case 
    when  self.contact_type == 'Website Problem'
      self.github_issue
    when self.contact_type == 'Data Problem'
      UserMailer.copy_to_contact_person(self).deliver
      data_manager_issue(self)
    when self.contact_type == 'Volunteer'
      volunteering_issue(self) 
    when self.contact_type == 'Question' || self.contact_type == "Thank you"
      ccs = Array.new
      UseridDetail.where(:person_role => 'contacts_coordinator').all.each do |person|
        ccs << person.email_address unless person.nil?
      end
      UserMailer.contact(self,ccs).deliver
    end
  end

  def github_issue
    ccs = Array.new
    UseridDetail.where(:person_role => 'system_administrator').all.each do |person|
     ccs << person.email_address
    end
    UserMailer.website(self,ccs).deliver
    if Contact.github_enabled
      Octokit.configure do |c|
        c.login = Rails.application.config.github_login
        c.password = Rails.application.config.github_password
      end
      response = Octokit.create_issue(Rails.application.config.github_repo, issue_title, issue_body, :labels => [])
      logger.info(response)
      self.github_issue_url = response[:html_url]
      self.save!
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

  def general_issue(contact)
    ccs = Array.new
    UseridDetail.where(:person_role => 'system_administrator').all.each do |person|
      ccs << person.person_forename
    end
    UseridDetail.where(:person_role => 'system_administrator').all.each do |person|
      UserMailer.contact_to_freexxx_manager(contact,person,ccs).deliver
    end
  end
  
  def data_manager_issue(contact)
    ccs = Array.new
    coordinator = contact.get_coordinator if contact.record_id.present?
    ccs << coordinator.person_forename if contact.record_id.present? && coordinator.present?
    UseridDetail.where(:person_role => 'data_manager').all.each do |person|
      ccs << person.person_forename
    end
    UserMailer.contact_to_coordinator(contact,coordinator,ccs).deliver if coordinator.present?
    UseridDetail.where(:person_role => 'data_manager').all.each do |data_manager|
      UserMailer.contact_to_recipient(contact,data_manager,ccs).deliver unless coordinator.present?
      UserMailer.contact_to_data_manager(contact,data_manager,ccs).deliver if coordinator.present?
    end
  end
  def volunteering_issue(contact)
    ccs = Array.new
    UseridDetail.where(:person_role => 'volunteer_coordinator').all.each do |person|
       ccs << person.email_address
    end
    if MyopicVicar::Application.config.template_set == 'freereg'
      manager = UseridDetail.where(:userid => 'REGManager').first
    elsif MyopicVicar::Application.config.template_set == 'freecen'
      manager = UseridDetail.where(:userid => 'CENManager').first
    else
      manager = nil
    end
    ccs << manager.person_forename unless manager.nil?
    UseridDetail.where(:person_role => 'volunteer_coordinator').all.each do |volunteer|
     UserMailer.contact_to_volunteer(contact,volunteer,ccs).deliver
    end
    UserMailer.contact_to_volunteer(contact,manager,ccs).deliver unless manager.nil?
  end

  def get_coordinator
    return nil if MyopicVicar::Application.config.template_set == 'freecen'
    entry = SearchRecord.find(self.record_id).freereg1_csv_entry
    record = Freereg1CsvEntry.find(entry)
    file = record.freereg1_csv_file
    county = file.county #this is chapman code
    coordinator = UseridDetail.where(:userid => County.where(:chapman_code => county).first.county_coordinator).first
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
