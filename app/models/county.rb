class County
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  require 'chapman_code'
  require 'freereg_options_constants'
  require 'freecen_constants'
  require 'app'

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
  field :census_records, type: String, default: ''

  has_many :freecen2_districts, dependent: :restrict_with_error

  before_save :add_lower_case_and_change_userid_fields

  index ({ chapman_code: 1, county_coordinator: 1 })
  index ({ county_coordinator: 1 })
  index ({ previous_county_coordinator: 1 })
  index ({ county_coordinator_lower_case: 1})
  index ({ chapman_code: 1, county_coordinator_lower_case: 1 })
  index ({ chapman_code: 1, previous_county_coordinator: 1 })

  class << self
    def application_counties
      case App.name_downcase
      when 'freereg'
        counties = County.where(:county_description.nin => FreeregOptionsConstants::CHAPMAN_CODE_ELIMINATIONS).order_by(chapman_code: 1)
      when 'freecen'
        counties = County.where(:county_description.nin => Freecen::CHAPMAN_CODE_ELIMINATIONS).order_by(chapman_code: 1)
      end
      counties
    end

    def chapman_code(chapman)
      where(chapman_code: chapman)
    end

    def county_description(county_description)
      where(county_description: county_description)
    end

    def coordinator_name(chapman_code)
      coordinator_name = ''
      if chapman_code.present? && ChapmanCode.values.include?(chapman_code)
        county = County.find_by(chapman_code: chapman_code)
        if county.present?
          coordinator_id = UseridDetail.find_by(userid: county.county_coordinator)
          coordinator_name = coordinator_id.person_forename + ' ' + coordinator_id.person_surname if coordinator_id.present?
        end
      end
      coordinator_name
    end

    def coordinator_email_address(chapman_code)
      coordinator_email_address = ''
      if chapman_code.present? && ChapmanCode.values.include?(chapman_code)
        county = County.find_by(chapman_code: chapman_code)
        if county.present?
          coordinator_id = UseridDetail.find_by(userid: county.county_coordinator)
          coordinator_email_address = coordinator_id.email_address if coordinator_id.present?
        end
      end
      coordinator_email_address
    end

    def coordinator(userid)
      where(county_coordinator: userid)
    end

    def county_with_unallocated_image_groups
      counties = []
      image_server_group = []

      place_id = Place.all.pluck(:id, :chapman_code).to_h
      place_county = Hash.new { |h, k| h[k] = [] }.tap { |h| place_id.each { |k, v| h[k] = v } }

      image_server_group = ImageServerGroup.where("summary.status" => { '$in' => ['u'] }).pluck(:id, :place_id)
      group_id = Hash.new { |h, k| h[k] = [] }.tap { |h| image_server_group.each { |k, v| h[k] = v } }

      group_id.each do |_group, place|
        counties << place_county[place] unless counties.include?(place_county[place])
      end
      counties
    end

    def county?(code)
      result = County.chapman_code(code).present? ? true : false
      result
    end

    def id(id)
      where(id: id)
    end

    def inactive_counties
      valid_codes = ChapmanCode.chapman_codes_for_reg_county
      actual_codes = County.all.pluck(:chapman_code).uniq
      values_for_selection = valid_codes.delete_if { |code| actual_codes.include?(code) }
      values = []
      values_for_selection.each do |code|
        values << ChapmanCode.has_key(code)
      end
      values
    end

    def records(chapman)
      files = Freereg1CsvFile.county(chapman).all
      record = []
      records = 0
      records_ma = 0
      records_ba = 0
      records_bu = 0
      number_files = 0
      files.each do |file|
        records = records.to_i + file.records.to_i unless file.records.nil?
        case file.record_type
        when 'ba'
          records_ba = records_ba + file.records.to_i unless file.records.nil?
        when 'ma'
          records_ma = records_ma + file.records.to_i unless file.records.nil?
        when 'bu'
          records_bu = records_bu + file.records.to_i unless file.records.nil?
        end
      end
      number_files = files.length if files.present?
      record[0] = records
      record[1] = records_ba
      record[2] = records_bu
      record[3] = records_ma
      record[4] = number_files
      record
    end
  end

  def add_lower_case_and_change_userid_fields
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
        if @old_userid.county_groups.present? && @old_userid.county_groups.length == 1
          unless (@old_userid.person_role == 'system_adminstrator' || @old_userid.person_role == 'volunteer_coordinator' || @old_userid.person_role == 'technical' || @old_userid.person_role == 'data_manager' )
            @old_userid.person_role = 'transcriber' if @old_userid.syndicate_groups.nil?
            @old_userid.person_role = 'syndicate_coordinator' if @old_userid.syndicate_groups.present? && @old_userid.syndicate_groups.length >= 1
          end # role
        end #length
        @old_userid.county_groups.delete_if { |code| code == self.chapman_code } unless @old_userid.county_groups.nil?
        @old_userid.save(validate: false) if @old_userid.present?
      end ## old exists

      if  @new_userid.present? # make sure there is a new coordinator to upgrade
        if @new_userid.county_groups.nil? || @new_userid.county_groups.length == 0 then
          @new_userid.person_role = 'county_coordinator' if (@new_userid.person_role == 'transcriber' || @new_userid.person_role == 'syndicate_coordinator' || @new_userid.person_role == 'researcher')
        end #groups
        @new_userid.county_groups = [] if @new_userid.county_groups.blank?
        @new_userid.county_groups << self.chapman_code
        @new_userid.county_groups = @new_userid.county_groups.compact
        @new_userid.save(validate: false) if @new_userid.present?
      end #exists
    end #no change in coordinator
    parameters
  end

end
