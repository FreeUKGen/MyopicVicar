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
  field :open_data, type: Boolean, default: true
  field :url, type: String #if the source is locatable online, this is the URL for the top-level (not single-page) webpage for it

  belongs_to :register, index: true
  has_many :image_server_groups, foreign_key: :source_id, :dependent=>:restrict # includes transcripts, printed editions, and microform, and digital versions of these
  has_many :assignments, :dependent=>:restrict

  accepts_nested_attributes_for :image_server_groups, :reject_if => :all_blank
  attr_accessor :propagate
  
  index({register_id:1, source_name:1},{name: "register_id_source_name"})

  # TODO: name for "Great Register" vs "Baptsm" -- use RecordType?  Extend it?

  class << self

    def id(id)
      where(:id => id)
    end

    def register_id(id)
      where(:register_id => id)
    end

    def find_by_register_ids(id)
      where(:register_id => {'$in'=>id.keys})
    end
    
    def get_source_ids(chapman_code)
      if chapman_code.nil?
        return nil, nil
      else
        source_id = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
        place_id = Place.chapman_code(chapman_code).pluck(:id, :place_name).to_h

        church = Church.find_by_place_ids(place_id).pluck(:id, :place_id, :church_name)
        church_id = Hash.new{|h,k| h[k]=[]}.tap{|h| church.each{|k,v,w| h[k] << v << w}}

        register = Register.find_by_church_ids(church_id).pluck(:id, :church_id, :register_type)
        register_id = Hash.new{|h,k| h[k]=[]}.tap{|h| register.each{|k,v,w| h[k] << v << w}}

        source = Source.find_by_register_ids(register_id).pluck(:id, :register_id, :source_name)
        x = Hash.new{|h,k| h[k]=[]}.tap{|h| source.each{|k,v,w| h[k] << v << w}}

        sid = []
        x.each do |k1,v1|
        # build hash @source_id[place_name][church_name][register_type][source_name] = source_id
          source_id[place_id[church_id[register_id[v1[0]][0]][0]]][church_id[register_id[v1[0]][0]][1]][register_id[v1[0]][1]][v1[1]] = k1

          register_type = register_id[v1[0]][1]
          church_name = church_id[register_id[v1[0]][0]][1]
          place_name = place_id[church_id[register_id[v1[0]][0]][0]]
          sid << [k1, place_name, church_name, register_type, v1[1]]
        end
        s_id = sid.sort_by {|a,b,c,d,e| [b,c,d,e]}
        return s_id, source_id
      end
    end

    def get_unitialized_source_list(chapman_code)
      uninitialized_source = Hash.new

      if chapman_code.nil?
        return nil, nil
      else
        source_id = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
        place_id = Place.chapman_code(chapman_code).pluck(:id, :place_name).to_h

        church = Church.find_by_place_ids(place_id).pluck(:id, :place_id, :church_name)
        church_id = Hash.new{|h,k| h[k]=[]}.tap{|h| church.each{|k,v,w| h[k] << v << w}}

        register = Register.find_by_church_ids(church_id).pluck(:id, :church_id, :register_type)
        register_id = Hash.new{|h,k| h[k]=[]}.tap{|h| register.each{|k,v,w| h[k] << v << w}}

        source1 = Source.find_by_register_ids(register_id).pluck(:id, :register_id, :source_name)
        sourceid = Hash.new{|h,k| h[k]=[]}.tap{|h| source1.each{|k,v,w| h[k] << v << w}}

        image_server_group = ImageServerGroup.find_by_source_ids(sourceid).pluck(:id, :source_id)
        image_server_group_id = Hash.new{|h,k| h[k]=[]}.tap{|h| image_server_group.each{|k,v| h[k]=v}}

        image_server_image = ImageServerImage.collection.aggregate([
                    {'$match'=>{"image_server_group_id"=>{'$in': image_server_group_id.keys}}},
                    {'$group'=>{_id: {id:'$image_server_group_id',status:'$status'}}}
                ])

        image_server_image.each do |x|
          if x[:_id][:status].nil?
            group_id = x[:_id][:id]
            uninitialized_source[image_server_group_id[group_id]] = 1
          end
        end

        sourceid.each do |k1,v1| 
          sourceid.delete(k1) if !uninitialized_source.keys.include?(k1) || uninitialized_source.empty?
        end

        sid = []
        sourceid.each do |k1,v1|
        # build hash @source_id[place_name][church_name][register_type][source_name] = source_id
          source_id[place_id[church_id[register_id[v1[0]][0]][0]]][church_id[register_id[v1[0]][0]][1]][register_id[v1[0]][1]][v1[1]] = k1

          register_type = register_id[v1[0]][1]
          church_name = church_id[register_id[v1[0]][0]][1]
          place_name = place_id[church_id[register_id[v1[0]][0]][0]]
          sid << [k1, place_name, church_name, register_type, v1[1]]
        end
        s_id = sid.sort_by {|a,b,c,d,e| [b,c,d,e]}
        return s_id, source_id
      end
    end

  end
end
