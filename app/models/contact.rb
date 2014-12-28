class Contact
  include Mongoid::Document
  include Mongoid::Timestamps
  field :title, type: String
  field :body, type: String
  field :contact_time, type: DateTime
  field :contact_syndicate, type: String
  field :contact_county, type: String
  field :contact_management, type: String
  field :name, type: String
  field :email_address, type: String
  field :session_id, type: String
  field :problem_page_url, type: String
  field :previous_page_url, type: String
  field :contact_type, type: String
  field :github_issue_url, type: String
  field :session_data, type: Hash
  field :screenshot, type: String
  field :contact_name, type: String, default: nil  # this field is used as a span trap
  validates_presence_of :name, :email_address, :title, :contact_type
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
    case contact_type
    when 'Website Problem'
      github_issue
    when 'Data Problem'
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
    "#{title} (#{name})"
  end
  
  def general_issue
    p 'general_issue'
    p self
    UserMailer.contact_to_freereg_manager(self).deliver if self.contact_management == 'FreeREG'
    UserMailer.contact_to_freeukgen_manager(self).deliver if self.contact_management == 'FreeUKGen'
    @options_syndicates =  Array.new
    Syndicate.all.order_by(syndicate_code: 1).each do |syndicate|
     @options_syndicates <<   syndicate.syndicate_code
    end
    @options_counties =  Array.new
    County.all.order_by(chapman_code: 1).each do |county|
        @options_counties << county.chapman_code
    end
    if @options_syndicates.include? self.contact_syndicate
      coordinator = Syndicate.where(:syndicate_code => self.contact_syndicate).first.syndicate_coordinator
      coordinator = UseridDetail.where(:userid => coordinator).first
      UserMailer.contact_to_recipient(self,coordinator).deliver
    end
    if @options_counties.include? self.contact_county
      coordinator = County.where(:chapman_code => self.contact_county).first.county_coordinator
      coordinator = UseridDetail.where(:userid => coordinator).first
      UserMailer.contact_to_recipient(self,coordinator).deliver
    end
  end

  def data_manager_issue
    p "data manager"
    p self
    UseridDetail.where(:person_role => 'data_manager').all.each do |data_manager|
    UserMailer.contact_to_recipient(self,data_manager).deliver 
    end
  end

  def issue_body
    issue_body = ApplicationController.new.render_to_string(:partial => 'contacts/github_issue_body.txt', :locals => {:feedback => self})
    issue_body
  end

end
