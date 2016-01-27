class County

  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short

  field :chapman_code, type: String
  field :county_coordinator, type: String
  field :previous_county_coordinator, type: String
  field :county_coordinator_lower_case,  type: String
  field :county_description, type: String
  field :county_notes, type: String

  before_save :add_lower_case_and_change_userid_fields

  index ({ chapman_code: 1, county_coordinator: 1 })
  index ({ county_coordinator: 1 })
  index ({ previous_county_coordinator: 1 })
  index ({ county_coordinator_lower_case: 1})
  index ({ chapman_code: 1, county_coordinator_lower_case: 1 })
  index ({ chapman_code: 1, previous_county_coordinator: 1 })
  class << self
    def id(id)
      where(:id => id)
    end
  end


  def update_fields_before_applying(parameters)
    previous_county_coordinator = self.county_coordinator
    parameters[:previous_county_coordinator] = previous_county_coordinator  unless self.county_coordinator == parameters[:county_coordinator]
    unless self.county_coordinator == parameters[:county_coordinator] #no change in coordinator
      if UseridDetail.where(:userid => previous_county_coordinator).exists? then #make sure that
        @old_userid = UseridDetail.where(:userid => previous_county_coordinator).first
        if @old_userid.county_groups.present? && @old_userid.county_groups.length == 1
          unless  (@old_userid.person_role == 'system_adminstrator' || @old_userid.person_role == 'volunteer_coordinator' || @old_userid.person_role == 'technical' || @old_userid.person_role == 'data_manager' )
            @old_userid.person_role = 'transcriber'  if @old_userid.syndicate_groups.nil?
            @old_userid.person_role = 'syndicate_coordinator' if @old_userid.syndicate_groups.present? && @old_userid.syndicate_groups.length >= 1
          end # role
        end #length
        @old_userid.county_groups.delete_if {|code| code == self.chapman_code} unless @old_userid.county_groups.nil?
        @old_userid.save(:validate => false)  unless @old_userid.nil?
      end ## old exists
      if UseridDetail.where(:userid => parameters[:county_coordinator]).exists? then # make sure there is a new coordinator to upgrade
        @new_userid = UseridDetail.where(:userid => parameters[:county_coordinator]).first
        if @new_userid.county_groups.nil? || @new_userid.county_groups.length == 0 then
          @new_userid.person_role = 'county_coordinator' if (@new_userid.person_role == 'transcriber' || @new_userid.person_role == 'syndicate_coordinator' || @new_userid.person_role == 'researcher')
        end #groups
        @new_userid.county_groups = Array.new if  @new_userid.county_groups.nil? || @new_userid.county_groups.empty?
        @new_userid.county_groups << self.chapman_code
        @new_userid.county_groups = @new_userid.county_groups.compact
        @new_userid.save(:validate => false)  unless @new_userid.nil?
      end #exists
    end #no change in coordinator
    parameters
  end
  protected

  def  add_lower_case_and_change_userid_fields
    self.county_coordinator_lower_case = self.county_coordinator.downcase

  end
  def self.coordinator_name(chapman_code)
    if chapman_code.nil?
      #test needed as bots are coming through without a session and hence no chapman code is set
      coordinator_name = ""
    else
      coordinator_userid = County.where(:chapman_code => chapman_code ).first.county_coordinator
      coordinator_id = UseridDetail.where(:userid => coordinator_userid).first
      if coordinator_id.nil?
        coordinator_name = nil
      else
        coordinator_name = coordinator_id.person_forename + "  " + coordinator_id.person_surname
      end
    end
    coordinator_name
  end
end
