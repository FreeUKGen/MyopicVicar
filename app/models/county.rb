class County

  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  require 'chapman_code'

  field :chapman_code, type: String
  field :county_coordinator, type: String
  field :previous_county_coordinator, type: String
  field :county_coordinator_lower_case,  type: String
  field :county_description, type: String
  field :county_notes, type: String
  field :files, type: String
  field :total_records, type: String
  field :baptism_records, type: String
  field :burial_records, type: String
  field :marriage_records, type: String

  before_save :add_lower_case_and_change_userid_fields

  index ({ chapman_code: 1, county_coordinator: 1 })
  index ({ county_coordinator: 1 })
  index ({ previous_county_coordinator: 1 })
  index ({ county_coordinator_lower_case: 1})
  index ({ chapman_code: 1, county_coordinator_lower_case: 1 })
  index ({ chapman_code: 1, previous_county_coordinator: 1 })

  class << self

    def chapman_code(chapman)
      where(:chapman_code => chapman)
    end

    def coordinator_name(chapman_code)
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

    def coordinator(userid)
      where(:county_coordinator => userid)
    end

    def is_county(code)
      County.chapman_code(code).present?  ? result = true : result = false
      result
    end

    def id(id)
      where(:id => id)
    end

    def records(chapman)
      files = Freereg1CsvFile.county(chapman).all
      record = Array.new
      records = 0
      records_ma = 0
      records_ba = 0
      records_bu = 0
      number_files = 0
      files.each do |file|
        records = records.to_i + file.records.to_i unless file.records.nil?
        case file.record_type
        when "ba"
          records_ba = records_ba + file.records.to_i unless file.records.nil?
        when "ma"
          records_ma = records_ma + file.records.to_i unless file.records.nil?
        when "bu"
          records_bu = records_bu + file.records.to_i unless file.records.nil?
        end
      end
      number_files = files.length unless files.blank?
      record[0] = records
      record[1] = records_ba
      record[2] = records_bu
      record[3] = records_ma
      record[4] = number_files
      record
    end
  end

  def  add_lower_case_and_change_userid_fields
    self.county_coordinator_lower_case = self.county_coordinator.downcase
  end

  def update_fields_before_applying(parameters)
    previous_county_coordinator = self.county_coordinator
    @new_userid = UseridDetail.id(parameters[:county_coordinator]).first
    if @new_userid.present?
      parameters[:county_coordinator] = @new_userid.userid
    else
      parameters[:county_coordinator] = self.county_coordinator
    end
    @old_userid = UseridDetail.userid(previous_county_coordinator).first
    unless self.county_coordinator == parameters[:county_coordinator] #no change in coordinator
      if @old_userid.present? then #make sure that
        parameters[:previous_county_coordinator] = @old_userid.userid
        if @old_userid.county_groups.length == 1
          unless  (@old_userid.person_role == 'system_adminstrator' || @old_userid.person_role == 'volunteer_coordinator' || @old_userid.person_role == 'technical' || @old_userid.person_role == 'data_manager' )
            @old_userid.person_role = 'transcriber'  if @old_userid.syndicate_groups.nil?
            @old_userid.person_role = 'syndicate_coordinator' if @old_userid.syndicate_groups.present? && @old_userid.syndicate_groups.length >= 1
          end # role
        end #length
        @old_userid.county_groups.delete_if {|code| code == self.chapman_code}
        @old_userid.save(:validate => false)  unless @old_userid.nil?
      end ## old exists

      if  @new_userid.present? # make sure there is a new coordinator to upgrade
        if @new_userid.county_groups.nil? || @new_userid.county_groups.length == 0 then
          @new_userid.person_role = 'county_coordinator' if (@new_userid.person_role == 'transcriber' || @new_userid.person_role == 'syndicate_coordinator' || @new_userid.person_role == 'researcher')
        end #groups
        @new_userid.county_groups = Array.new if  @new_userid.county_groups.nil? || @new_userid.county_groups.empty?
        @new_userid.county_groups << self.chapman_code
        @new_userid.county_groups = @new_userid.county_groups.compact
        @new_userid.save(:validate => false)  unless @new_userid.blank?
      end #exists
    end #no change in coordinator
    parameters
  end

end
