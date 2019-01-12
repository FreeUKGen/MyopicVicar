class Source
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short

  field :source_name, type: String
  field :notes, type: String
  field :start_date, type: String
  field :end_date, type: String
  field :folder_name, type: String

  field :original_form, type: Hash, default: {}
  field :original_owner, type: String
  field :creating_institution, type: String
  field :holding_institution, type: String
  field :restrictions_on_use_by_creating_institution, type: String
  field :restrictions_on_use_by_holding_institution, type: String
  field :open_data, type: Boolean, default: false
  field :url, type: String #if the source is locatable online, this is the URL for the top-level (not single-page) webpage for it

  attr_accessor :initialize_status

  belongs_to :register, index: true
  has_many :image_server_groups, foreign_key: :source_id, :dependent=>:restrict # includes transcripts, printed editions, and microform, and digital versions of these
  has_many :assignments, :dependent=>:restrict

  accepts_nested_attributes_for :image_server_groups, :reject_if => :all_blank
  attr_accessor :propagate

  validate :errors_in_fields

  index({ register_id: 1, source_name: 1 }, name: "register_id_source_name" )

  # TODO: name for "Great Register" vs "Baptsm" -- use RecordType?  Extend it?

  class << self

    def id(id)
      where(id: id)
    end

    def register_id(id)
      where(register_id: id)
    end

    def find_by_register_ids(id)
      where(register_id: { '$in' => id.keys })
    end

    def create_manage_image_server_url(userid, role, chapman_code)
      URI.escape(Rails.application.config.image_server + 'manage_freereg_images/' + 'access?userid=' + userid + '&role=' + role + '&chapman_code=' + chapman_code + '&image_server_access=' + Rails.application.config.image_server_access)
    end

    def get_propagate_source_list(source)
      @source_id = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

      place = source.register.church.place
      place_id = Place.where(chapman_code: place.chapman_code).pluck(:id, :place_name).to_h

      church_id = Church.where(place_id: { '$in' => place_id.keys }).pluck(:id, :place_id, :church_name)
      church_id = Hash.new{ |h, k| h[k] = [] }.tap{ |h| church_id.each{ |k, v, w| h[k] << v << w } }

      register_id = Register.where(church_id: { '$in' => church_id.keys }).pluck(:id, :church_id, :register_type)
      register_id = Hash.new{ |h, k| h[k] = [] }.tap{ |h| register_id.each{ |k, v, w| h[k] << v << w } }

      x = Source.where(register_id: { '$in' => register_id.keys }, source_name: source.source_name).pluck(:id, :register_id).to_h

      x.each do |k1, v1|
        @source_id['Place: ' + place_id[church_id[register_id[v1][0]][0]] + ', Church: ' + church_id[register_id[v1][0]][1] + ' - ' + RegisterType.display_name(register_id[v1][1])] = k1
      end

      @source_id
    end

    def get_source_ids(chapman_code)
      return nil, nil if chapman_code.blank?

      source_id = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
      place_id = Place.chapman_code(chapman_code).pluck(:id, :place_name).to_h

      church = Church.find_by_place_ids(place_id).pluck(:id, :place_id, :church_name)
      church_id = Hash.new{ |h, k| h[k] = [] }.tap{ |h| church.each{ |k, v, w| h[k] << v << w } }

      register = Register.find_by_church_ids(church_id).pluck(:id, :church_id, :register_type)
      register_id = Hash.new{ |h, k| h[k] = [] }.tap{ |h| register.each{ |k, v, w| h[k] << v << w } }

      source = Source.find_by_register_ids(register_id).pluck(:id, :register_id, :source_name)
      return nil, nil if source.blank?

      x = Hash.new{ |h, k| h[k] = [] }.tap{ |h| source.each{ |k, v, w| h[k] << v << w } }

      sid = []
      x.each do |k1, v1|
        # build hash @source_id[place_name][church_name][register_type][source_name] = source_id
        source_id[place_id[church_id[register_id[v1[0]][0]][0]]][church_id[register_id[v1[0]][0]][1]][register_id[v1[0]][1]][v1[1]] = k1

        register_type = register_id[v1[0]][1]
        church_name = church_id[register_id[v1[0]][0]][1]
        place_name = place_id[church_id[register_id[v1[0]][0]][0]]
        sid << [k1, place_name, church_name, register_type, v1[1]]
      end

      return nil, nil if sid.blank?

      s_id = sid.sort_by { |a, b, c, d, e| [b, c, d, e] }
      return s_id, source_id
    end

    def get_unitialized_source_list(chapman_code)
      return nil, nil if chapman_code.nil?

      initialized_source = Hash.new
      source_id = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
      place_id = Place.chapman_code(chapman_code).pluck(:id, :place_name).to_h

      church = Church.find_by_place_ids(place_id).pluck(:id, :place_id, :church_name)
      church_id = Hash.new{ |h, k| h[k] = [] }.tap{ |h| church.each{ |k, v, w| h[k] << v << w } }

      register = Register.find_by_church_ids(church_id).pluck(:id, :church_id, :register_type)
      register_id = Hash.new{ |h, k| h[k] = [] }.tap{ |h| register.each{ |k, v, w| h[k] << v << w } }

      source1 = Source.find_by_register_ids(register_id).pluck(:id, :register_id, :source_name)
      sourceid = Hash.new{ |h, k| h[k] = [] }.tap{ |h| source1.each{ |k, v, w| h[k] << v << w } }

      image_server_group = ImageServerGroup.find_by_source_ids(sourceid).pluck(:id, :source_id)
      image_server_group_id = Hash.new{ |h, k| h[k] = []} .tap{ |h| image_server_group.each{ |k, v| h[k] = v } }

      image_server_image = ImageServerImage.collection.aggregate([
                                                                   {'$match' => { "image_server_group_id" => { '$in': image_server_group_id.keys } } },
                                                                   {'$group' => { _id: { id: '$image_server_group_id', status: '$status' } } }
      ])

      image_server_image.each do |x|
        if x[:_id][:status].present?
          group_id = x[:_id][:id]
          initialized_source[image_server_group_id[group_id]] = 1
        end
      end

      sourceid.each do |k1, v1|
        sourceid.delete(k1) if initialized_source.keys?(k1)
      end

      sid = []
      sourceid.each do |k1, v1|
        # build hash @source_id[place_name][church_name][register_type][source_name] = source_id
        source_id[place_id[church_id[register_id[v1[0]][0]][0]]][church_id[register_id[v1[0]][0]][1]][register_id[v1[0]][1]][v1[1]] = k1

        register_type = register_id[v1[0]][1]
        church_name = church_id[register_id[v1[0]][0]][1]
        place_name = place_id[church_id[register_id[v1[0]][0]][0]]
        sid << [k1, place_name, church_name, register_type, v1[1]]
      end

      return nil, nil if sid.blank?

      s_id = sid.sort_by { |a, b, c, d, e| [b, c, d, e] }
      [s_id, source_id]
    end

    def update_for_propagate(params)
      original_form_type = params[:source][:original_form][:type]
      original_form_name = params[:source][:original_form][:name]
      original_owner = params[:source][:original_owner]
      creating_institution = params[:source][:creating_institution]
      holding_institution = params[:source][:holding_institution]
      restrictions_on_use_by_creating_institution = params[:source][:restrictions_on_use_by_creating_institution]
      restrictions_on_use_by_holding_institution = params[:source][:restrictions_on_use_by_holding_institution]
      open_data = params[:source][:open_data]
      url = params[:source][:url]
      source_list = params[:source][:propagate][:source_id]
      source_list << params[:id]

      Source.where(id:{ '$in' => source_list })
      .update_all(original_owner: original_owner,
                  original_form: { type: original_form_type, name: original_form_name },
                  creating_institution: creating_institution,
                  holding_institution: holding_institution,
                  restrictions_on_use_by_creating_institution: restrictions_on_use_by_creating_institution,
                  restrictions_on_use_by_holding_institution: restrictions_on_use_by_holding_institution,
                  open_data: open_data,
                  url: url)
    end
  end

  def errors_in_fields
    errors.add(:source_name, 'Source name not selected') if source_name.blank?
    errors.add(:start_date, 'Invalid start year') if start_date.present? && (start_date.to_i <= 1 || start_date.to_i > Time.now.year)
    errors.add(:end_date, 'Invalid end year') if end_date.present? && (end_date.to_i <= 1 || end_date.to_i > Time.now.year)
    errors.add(:end_date, 'Start year greater than end year') if end_date.present? && start_date.present? && start_date.to_i > end_date.to_i
  end
end
