class Syndicate
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short

  field :syndicate_code, type: String
  field :previous_syndicate_code, type: String
  field :syndicate_coordinator, type: String
  field :syndicate_coordinator_lower_case, type: String
  field :previous_syndicate_coordinator, type: String
  field :syndicate_description, type: String
  field :syndicate_notes, type: String
  field :accepting_transcribers, type: Boolean, default: true
  field :changing_name, type: Boolean, default: false
  before_save :add_lower_case_and_change_userid_fields
  after_save :propagate_change_in_code
  validate :syndicate_code_does_not_exist_on_change, on: :update

  has_many :assignments

  index ({ syndicate_code: 1, syndicate_coordinator: 1 })
  index ({ syndicate_coordinator: 1 })
  index ({ previous_syndicate_coordinator: 1 })

  class << self
    def id(id)
      where(:id => id)
    end

    def coordinator(userid)
      where(:syndicate_coordinator => userid)
    end

    def syndicate_code(code)
      where(:syndicate_code => code)
    end

    def is_syndicate(code)
      Syndicate.syndicate_code(code).present?  ? result = true : result = false
      result
    end

    def get_syndicates
      @syndicates = Syndicate.all.order_by(:syndicate_code=>1).pluck(:syndicate_code)
      @syndicates
    end
  end

  def  add_lower_case_and_change_userid_fields
    self.syndicate_coordinator_lower_case = self.syndicate_coordinator.downcase

  end
  def update_fields_before_applying(parameters)
    unless self.syndicate_code ==  parameters[:syndicate_code]
      parameters[:changing_name] = true
      parameters[:previous_syndicate_code] = self.syndicate_code
    end
    previous_syndicate_coordinator = self.syndicate_coordinator
    parameters[:previous_syndicate_coordinator] = previous_syndicate_coordinator  unless self.syndicate_coordinator == parameters[:syndicate_coordinator]
    unless self.syndicate_coordinator == parameters[:syndicate_coordinator]
      #change coordinators
      self.remove_syndicate_from_coordinator
      self.downgrade_syndicate_coordinator_person_role
      self.add_syndicate_to_coordinator(parameters[:syndicate_code],parameters[:syndicate_coordinator])
      self.upgrade_syndicate_coordinator_person_role(parameters[:syndicate_coordinator])
    else
      #name change for an existing coordinator
      if  parameters[:changing_name]
        self.remove_syndicate_from_coordinator
        self.add_syndicate_to_coordinator(parameters[:syndicate_code],parameters[:syndicate_coordinator])
      end
    end#change of coordinator
    parameters
  end
  def propagate_change_in_code
    if self.changing_name
      UseridDetail.where(:syndicate => self.previous_syndicate_code).each do |user|
        user.update_attributes(:syndicate => self.syndicate_code)
      end
    end
  end
  def syndicate_code_does_not_exist_on_change
    errors.add(:syndicate_code, "Syndicate Already exists") if (Syndicate.where(:syndicate_code => self.syndicate_code).exists? && self.changing_name)
  end

  def self.get_syndicates_open_for_transcription
    @syndicates = Array.new
    syndicates = Syndicate.where(:accepting_transcribers.ne => false).all.order_by(syndicate_code: 1)
    syndicates.each do |syn|
      @syndicates << syn.syndicate_code
    end
    return @syndicates
  end

  def remove_syndicate_from_coordinator
    coordinator = UseridDetail.where(:userid => self.syndicate_coordinator).first
    unless coordinator.nil?
      unless coordinator.syndicate_groups.nil?
        coordinator.syndicate_groups.delete_if {|code| code == self.syndicate_code}
        coordinator.save(:validate => false)
      end
    end
  end
  def add_syndicate_to_coordinator(code,person)
    coordinator = UseridDetail.where(:userid => person).first
    coordinator.syndicate_groups = Array.new if coordinator.syndicate_groups.nil?
    coordinator.syndicate_groups << code
    coordinator.save(:validate => false)
  end

  def downgrade_syndicate_coordinator_person_role
    coordinator = UseridDetail.where(:userid => self.syndicate_coordinator).first
    unless coordinator.nil?
      unless coordinator.syndicate_groups.nil?
        coordinator.person_role = 'transcriber' if coordinator.syndicate_groups.length == 0 && coordinator.person_role == 'syndicate_coordinator'
        coordinator.save(:validate => false)
      end
    end
  end

  def upgrade_syndicate_coordinator_person_role(person)
    coordinator = UseridDetail.where(:userid => person).first
    coordinator.person_role = 'syndicate_coordinator' if  coordinator.person_role == 'transcriber' || coordinator.person_role == 'researcher'
    coordinator.save(:validate => false)
  end

  def self.get_users_for_syndicate(syndicate)
    users = Array.new
    UseridDetail.syndicate(syndicate).each do |user|
      users << user
    end
    users
  end

  def self.get_userids_for_syndicate(syndicate)
    userids = Array.new
    UseridDetail.syndicate(syndicate).each do |user|
      userids << user.userid
    end
    userids
  end

  def self.productive_volunteers(syndicate, start_date, end_date)
    stats = {}
    UseridDetail.syndicate(syndicate).each do |u|
      stats[u.userid] = []
      files = FreecenCsvFile.where(userid: u.userid, created_at: start_date..end_date)
      next unless files.present?
      files.each do |f|
        #stats << [f.userid, f.file_name, f.total_records]
        stats[u.userid] << [f.file_name, f.total_records]
      end
    end
    stats.select{|k,v| !v.empty?}
  end

end
