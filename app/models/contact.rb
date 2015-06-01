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
  validates_presence_of :name, :email_address
  validates :email_address,:format => {:with => /^[^@][\w\+.-]+@[\w.-]+[.][a-z]{2,4}$/i}

  mount_uploader :screenshot, ScreenshotUploader

  before_save :url_check
  after_create :communicate

  def url_check

    self.problem_page_url = "unknown" if self.problem_page_url.nil?
    self.previous_page_url = "unknown" if self.previous_page_url.nil?
  end

  def communicate
    UserMailer.copy_to_contact_person(self).deliver
    case 
    when  self.contact_type == 'Website Problem'
      github_issue
    when self.contact_type == 'Data Problem'
      data_manager_issue
    else
      general_issue
    end
  end

  def github_issue
    if Contact.github_enabled
      Octokit.configure do |c|
        c.login = Rails.application.config.github_login
        c.password = Rails.application.config.github_password
      end
      response = Octokit.create_issue(Rails.application.config.github_repo, issue_title, issue_body, :labels => [])
      logger.info(response)
      p response
      self.github_issue_url=response[:html_url]
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

  def general_issue
    UseridDetail.where(:person_role => 'system_administrator').all.each do |person|
    UserMailer.contact_to_freereg_manager(self,person).deliver
    end
  end

  def data_manager_issue
    p "contact"
    p self
    coordinator = self.get_coordinator if self.record_id.present?
    UserMailer.contact_to_coordinator(self,coordinator).deliver if coordinator.present?
    UseridDetail.where(:person_role => 'data_manager').all.each do |data_manager|
    UserMailer.contact_to_recipient(self,data_manager).deliver unless coordinator.present?
    UserMailer.contact_to_data_manager(self,data_manager,coordinator).deliver if coordinator.present?
    end

  end
  def get_coordinator
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



end
