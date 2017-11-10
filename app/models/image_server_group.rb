class ImageServerGroup
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  
  module Difficulty
    Complicated_Forms = 'c'
    Damaged = 'd'
    Learning = 'l'
    Post_1700_modern_freehand = 'p17'
    Post_1530_freehand_Secretary = 'p15s'
    Post_1530_freehand_Latin = 'p15l'
    Post_1530_freehand_Latin_Chancery = 'p15c'
    Straight_Forward_Forms = 's'

    ALL_DIFFICULTIES = {'c'=>'Complicated_Forms', 'd'=>'Damaged', 'l'=>'Learning', 'p17'=>'Post_1700_modern_freehand', 'p15s'=>'Post_1530_freehand_Secretary',  'p15l'=>'Post_1530_freehand_Latin', 'p15c'=>'Post_1530_freehand_Latin_Chancery', 's'=>'Straight_Forward_Forms'}
  end

  module Status
    UNALLOCATED = 'u'
    ALLOCATED = 'a'
    IN_PROGRESS = 'ip'
    TRANSCRIBED = 't'
    IN_REVIEW = 'ir'
    REVIEWED = 'r'
    COMPLETE = 'c'
    ERROR = 'e'

    ALL_STATUSES = {'u'=>'UNALLOCATED', 'a'=>'ALLOCATED', 'ip'=>'IN_PROGRESS', 't'=>'TRANSCRIBED', 'ir'=>'IN_REVIEW', 'r'=>'REVIEWED', 'c'=>'COMPLETE', 'e'=>'ERROR'}

    CHURCH_STATUS = {}

    REGISTER_STATUS = {
      'C4A' => 'image church name does not match the only existed church in FR, create church',
      'C4B' => 'image no church in file name and no church in FR from place name', # what to do?
      'C4C' => 'image church in file name matches the only existed chruch in FR', 
      'C4E' => 'image no church in file name, use the only existed church in FR as church',
      'C4F' => 'image church in file name match one record in FR', 
      'C4H' => 'image no church in file name, but multiple churches in FR', # what to do? skip right now
      'C5A' => 'image church name does not match the only existed church in FR, create church', 
      'C5B' => 'image church name does not match any existed church in FR, create church', 
      'R4A' => 'image not transcribed yet. File on IS does not have register type on FR, create register',
      'R4B' => 'image no register in file name and no register in FR from church name', # what to do?
      'R4C' => 'image register in file name matches the only register in FR', 
      'R4E' => 'image no register in file name, use the only existed register in FR as register', 
      'R4H' => 'image no register in file name, but multiple registers in FR', # what to do? skip right now
      'R6A1' => 'replace register " " on FR with IS image register type(when FR has one register',
      'R6B1' => 'replace register " " on FR with IS image register type(when FR has multiple registers'
    }
  end

  field :group_name, type: String
  field :start_date, type: String
  field :end_date, type: String
  field :summary, type: Hash, default:{}
  field :notes, type: String

  field :transcriber, type: Array, default: nil
  field :reviewer, type: Array, default: nil
  field :difficulty, type: String, default: nil
  field :status, type: String
  field :church_status, type: String
  field :register_status, type: String
  field :consistency, type: Mongoid::Boolean, default: false

  field :syndicate_code, type: String
  field :assign_date, type: String
  field :number_of_images, type: Integer

  attr_accessor :custom_field

  belongs_to :source, index: true
  belongs_to :place, index: true
  belongs_to :church, index: true
  has_many :image_server_images, foreign_key: :image_server_group_id, :dependent=>:restrict # includes images
  has_many :gaps

  accepts_nested_attributes_for :image_server_images, :reject_if => :all_blank
  

  # TODO: name for "Great Register" vs "Baptsm" -- use RecordType?  Extend it?

  class << self
    def calculate_image_numbers(group_list)
      @total = ImageServerImage.collection.aggregate([
                      {'$match'=>{"image_server_group_id"=>{'$in': group_list}}},
                      {'$group'=>{_id:'$image_server_group_id', 'count':{'$sum':1}}}
                ])

      @num = {}
      @total.each do |x|
        @num.store(x[:_id], x[:count])
      end

      @num
    end
    
    def check_all_images_status_before_initialize_source(source_id)
      image_server_group_ids = ImageServerGroup.source_id(source_id).pluck(:id)
      status = ImageServerImage.where(:image_server_group_id=>{'$in'=>image_server_group_ids}).distinct(:status)

      if status.sort == ['nil']
        return true
      else
        return false
      end
    end

    def find_by_source_ids(id)
      where(:source_id => {'$in'=>id.keys})
    end

    def get_group_ids_and_sort_by_syndicate(chapman_code)
      @syndicate = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

      @place_id = Place.chapman_code(chapman_code).pluck(:id, :place_name).to_h

      @church = Church.find_by_place_ids(@place_id).pluck(:id, :place_id, :church_name)
      @church_id = Hash.new{|h,k| h[k]=[]}.tap{|h| @church.each{|k,v1,v2| h[k] << v1 << v2}}

      @register = Register.find_by_church_ids(@church_id).pluck(:id, :church_id, :register_type)
      @register_id = Hash.new{|h,k| h[k]=[]}.tap{|h| @register.each{|k,v1,v2| h[k] << v1 << v2}}

      @source = Source.find_by_register_ids(@register_id).pluck(:id, :register_id, :source_name)
      @source_id = Hash.new{|h,k| h[k]=[]}.tap{|h| @source.each{|k,v1,v2| h[k] << v1 << v2}}

      @image_server_group = ImageServerGroup.find_by_source_ids(@source_id).where(:syndicate_code=>{'$nin'=>['', nil]}).pluck(:id, :source_id, :group_name, :syndicate_code, :assign_date, :number_of_images)
      @sort_by_syndicate = @image_server_group.sort_by {|a,b,c,d,e,f| [b,d ? 0 : 1, d]}
      x = Hash.new{|h,k| h[k]=[]}.tap{|h| @sort_by_syndicate.each{|k,v1,v2,v3,v4,v5| h[k] << v1 << v2 << v3 << v4 << v5}}

      gid = []
      x.each do |key,value|
        # build hash @group_id[place_name][church_name][register_type][source_name][group_name] = group_id
        @syndicate[value[2]][@place_id[@church_id[@register_id[@source_id[value[0]][0]][0]][0]]][@church_id[@register_id[@source_id[value[0]][0]][0]][1]][@register_id[@source_id[value[0]][0]][1]][@source_id[value[0]][1]][value[1]] = key

        place_name = @place_id[@church_id[@register_id[@source_id[value[0]][0]][0]][0]]
        church_name = @church_id[@register_id[@source_id[value[0]][0]][0]][1]
        register_type = @register_id[@source_id[value[0]][0]][1]
        source_name = @source_id[value[0]][1]
        group_name = value[1]
        syndicate = value[2]
        assign_date = value[3]
        number_of_images = value[4]
        gid << [syndicate, key, place_name, church_name, register_type, source_name, group_name, assign_date, number_of_images]
      end
      @g_id = gid.sort_by {|a,b,c,d,e,f,g,h,i| [a ? 0:1, a.to_s.downcase,c,d,e,f]}

      return @source, @g_id, @syndicate
    end

    def get_group_ids_and_sort_not_by_syndicate(chapman_code, sort_by_place)
      @group_id = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

      @place_id = Place.chapman_code(chapman_code).pluck(:id, :place_name).to_h

      @church = Church.find_by_place_ids(@place_id).pluck(:id, :place_id, :church_name)
      @church_id = Hash.new{|h,k| h[k]=[]}.tap{|h| @church.each{|k,v1,v2| h[k] << v1 << v2}}

      @register = Register.find_by_church_ids(@church_id).pluck(:id, :church_id, :register_type)
      @register_id = Hash.new{|h,k| h[k]=[]}.tap{|h| @register.each{|k,v1,v2| h[k] << v1 << v2}}

      @source = Source.find_by_register_ids(@register_id).pluck(:id, :register_id, :source_name)
      @source_id = Hash.new{|h,k| h[k]=[]}.tap{|h| @source.each{|k,v1,v2| h[k] << v1 << v2}}

      if sort_by_place
        @image_server_group = ImageServerGroup.find_by_source_ids(@source_id).where(:syndicate_code=>{'$nin'=>['', nil]}).pluck(:id, :source_id, :group_name, :syndicate_code, :assign_date, :number_of_images)
      else
        @image_server_group = ImageServerGroup.find_by_source_ids(@source_id).pluck(:id, :source_id, :group_name, :syndicate_code, :assign_date, :number_of_images)
      end
      x = Hash.new{|h,k| h[k]=[]}.tap{|h| @image_server_group.each{|k,v1,v2,v3,v4,v5| h[k] << v1 << v2 << v3 << v4 << v5}}

      gid = []
      x.each do |key,value|
        # build hash @group_id[place_name][church_name][register_type][source_name][group_name] = group_id
        @group_id[@place_id[@church_id[@register_id[@source_id[value[0]][0]][0]][0]]][@church_id[@register_id[@source_id[value[0]][0]][0]][1]][@register_id[@source_id[value[0]][0]][1]][@source_id[value[0]][1]][value[1]] = key

        place_name = @place_id[@church_id[@register_id[@source_id[value[0]][0]][0]][0]]
        church_name = @church_id[@register_id[@source_id[value[0]][0]][0]][1]
        register_type = @register_id[@source_id[value[0]][0]][1]
        source_name = @source_id[value[0]][1]
        group_name = value[1]
        syndicate = value[2]
        assign_date = value[3]
        number_of_images = value[4]
        gid << [key, place_name, church_name, register_type, source_name, group_name, syndicate, assign_date, number_of_images]
      end
      @g_id = gid.sort_by {|a,b,c,d,e,f,g,h,i| [b,c,d,e,f ? 0:1,f.downcase]}

      return @source, @g_id, @group_id
    end

    def get_group_ids_for_available_assignment_by_county(chapman_code)
      @group_id = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

      @place_id = Place.chapman_code(chapman_code).pluck(:id, :place_name).to_h

      @church = Church.find_by_place_ids(@place_id).pluck(:id, :place_id, :church_name)
      @church_id = Hash.new{|h,k| h[k]=[]}.tap{|h| @church.each{|k,v1,v2| h[k] << v1 << v2}}

      @register = Register.find_by_church_ids(@church_id).pluck(:id, :church_id, :register_type)
      @register_id = Hash.new{|h,k| h[k]=[]}.tap{|h| @register.each{|k,v1,v2| h[k] << v1 << v2}}

      @source = Source.find_by_register_ids(@register_id).pluck(:id, :register_id, :source_name)
      @source_id = Hash.new{|h,k| h[k]=[]}.tap{|h| @source.each{|k,v1,v2| h[k] << v1 << v2}}

      @image_server_group = ImageServerGroup.find_by_source_ids(@source_id).where("summary.status"=>{'$in'=>['a','u']}).pluck(:id, :source_id, :group_name, :syndicate_code, :assign_date, :number_of_images)
      x = Hash.new{|h,k| h[k]=[]}.tap{|h| @image_server_group.each{|k,v1,v2,v3,v4,v5| h[k] << v1 << v2 << v3 << v4 << v5}}

      gid = []
      x.each do |key,value|
        # build hash @group_id[place_name][church_name][register_type][source_name][group_name] = group_id
        @group_id[@place_id[@church_id[@register_id[@source_id[value[0]][0]][0]][0]]][@church_id[@register_id[@source_id[value[0]][0]][0]][1]][@register_id[@source_id[value[0]][0]][1]][@source_id[value[0]][1]][value[1]] = key

        place_name = @place_id[@church_id[@register_id[@source_id[value[0]][0]][0]][0]]
        church_name = @church_id[@register_id[@source_id[value[0]][0]][0]][1]
        register_type = @register_id[@source_id[value[0]][0]][1]
        source_name = @source_id[value[0]][1]
        group_name = value[1]
        syndicate = value[2]
        assign_date = value[3]
        number_of_images = value[4]
        gid << [key, place_name, church_name, register_type, source_name, group_name, syndicate, assign_date, number_of_images]
      end
      @g_id = gid.sort_by {|a,b,c,d,e,f,g,h,i| [b,c,d,e,f ? 0:1,f.downcase]}

      return @source, @g_id, @group_id
    end

    def get_group_ids_for_syndicate(syndicate)
      @place_id = {}
      @source, @register, @church, gid = [], [], [], []
      @group_id = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

      group = ImageServerGroup.where(:syndicate_code=>syndicate)
      @image_server_group = group.pluck(:id, :source_id, :group_name, :syndicate_code, :assign_date, :number_of_images)
      source_ids = @image_server_group.map{|x| x[1]}.uniq

      source_ids.each do |sourceid|
        source = Source.find(sourceid)
        @source << [source.id, source.register_id, source.source_name]

        register = source.register
        @register << [register.id, register.church_id, register.register_type]

        church = register.church
        @church << [church.id, church.place_id, church.church_name]

        place_id = church.place
        @place_id[place_id.id] = place_id.place_name
      end

      @church_id = Hash.new{|h,k| h[k]=[]}.tap{|h| @church.each{|k,v1,v2| h[k] << v1 << v2}}
      @register_id = Hash.new{|h,k| h[k]=[]}.tap{|h| @register.each{|k,v1,v2| h[k] << v1 << v2}}
      @source_id = Hash.new{|h,k| h[k]=[]}.tap{|h| @source.each{|k,v1,v2| h[k] << v1 << v2}}
      x = Hash.new{|h,k| h[k]=[]}.tap{|h| @image_server_group.each{|k,v1,v2,v3,v4,v5| h[k] << v1 << v2 << v3 << v4 << v5}}

      x.each do |key,value|
        # build hash @group_id[place_name][church_name][register_type][source_name][group_name] = group_id
        @group_id[@place_id[@church_id[@register_id[@source_id[value[0]][0]][0]][0]]][@church_id[@register_id[@source_id[value[0]][0]][0]][1]][@register_id[@source_id[value[0]][0]][1]][@source_id[value[0]][1]][value[1]] = key

        place_name = @place_id[@church_id[@register_id[@source_id[value[0]][0]][0]][0]]
        church_name = @church_id[@register_id[@source_id[value[0]][0]][0]][1]
        register_type = @register_id[@source_id[value[0]][0]][1]
        source_name = @source_id[value[0]][1]
        group_name = value[1]
        syndicate = value[2]
        assign_date = value[3]
        number_of_images = value[4]
        gid << [key, place_name, church_name, register_type, source_name, group_name, syndicate, assign_date, number_of_images]
      end
      @g_id = gid.sort_by {|a,b,c,d,e,f,g,h,i| [b,c,d,e,f ? 0:1,f.downcase]}

      return @source, @g_id, @group_id
    end
    
    def get_sorted_group_name(source_id)    
      # get hash key=image_server_group_id, val=ig, sorted by ig
      ig_array = ImageServerGroup.where(:source_id=>source_id, :number_of_images=>{'$nin'=>[nil,'',0]}).pluck(:id, :group_name)
      @group_name = Hash[ig_array.map {|key,value| [key,value]}]

      @group_name
    end

    def id(id)
      where(:id => id)
    end

    def initialize_all_images_status_under_source(source_id,status)
      image_server_group_ids = ImageServerGroup.source_id(source_id).pluck(:id)
      ImageServerImage.where(:image_server_group_id=>{'$in'=>image_server_group_ids}).update_all(:status=>status)
      ImageServerGroup.where(:id=>{'$in'=>image_server_group_ids}).update_all('summary.status'=>[status])
    end

    def source_id(id)
      where(:source_id => id)
    end

    def summarize_from_image_server_image(summarization=nil)
      if self.count > 0
        group_id = self.first.id
        image_server_image = ImageServerImage.where(:image_server_group_id=>group_id)
        
        group_status = image_server_image.pluck(:status).compact.uniq
        group_difficulty = image_server_image.pluck(:difficulty).compact.uniq
        group_transcriber = image_server_image.pluck(:transcriber).flatten.compact.uniq
        group_reviewer = image_server_image.pluck(:reviewer).flatten.compact.uniq
        group_count = image_server_image.count

        summarization = [group_difficulty, group_status, group_transcriber, group_reviewer, group_count]
      end
      summarization
    end

    def update_image_group_summary(difficulty, status, transcriber, reviewer, count)
      group = self.first

      group.summary[:difficulty] = difficulty
      group.summary[:status] = status
      group.summary[:transcriber] = transcriber
      group.summary[:reviewer] = reviewer
      group.number_of_images = count if !count.nil?

      group.save
    end
    
  end
end
