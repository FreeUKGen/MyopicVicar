class ImageServerGroup
  require 'source_property'

  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short

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
  field :allocation_requested_by, type:String
  field :allocation_requested_through_syndicate, type: String


  attr_accessor :custom_field

  belongs_to :source, index: true
  belongs_to :place, index: true, optional: true
  belongs_to :church, index: true, optional: true
  has_many :image_server_images, foreign_key: :image_server_group_id, dependent: :restrict_with_error # includes images


  accepts_nested_attributes_for :image_server_images, :reject_if => :all_blank


  # TODO: name for "Great Register" vs "Baptsm" -- use RecordType?  Extend it?

  class << self
    def calculate_image_numbers(group_list)
      @total = ImageServerImage.collection.aggregate([
                                                       {'$match'=>{"image_server_group_id"=>{'$in': group_list}}},
                                                       {'$group'=>{_id:'$image_server_group_id', 'count':{'$sum':1}}}
      ])
      @num = Hash.new{ @total.each { |x| @num.store(x[:_id], x[:count]) }}

      return @num
    end

    def check_all_images_status_before_initialize_source(source_id)
      image_server_group_ids = ImageServerGroup.source_id(source_id).pluck(:id)
      status = ImageServerImage.where(:image_server_group_id=>{'$in'=>image_server_group_ids}).distinct(:status)

      if status.empty? || status == [''] || status == [nil]
        return true
      else
        return false
      end
    end

    def clean_params_before_update(image_server_group_params)
      image_server_group_params.delete(:origin)
      image_server_group_params.delete(:source_start_date)
      image_server_group_params.delete(:source_end_date)
      image_server_group_params.delete(:orig_group_name)
      image_server_group_params.delete(:orig_syndicate_code)

      return image_server_group_params
    end

    def email_cc_completion(group_id,chapman_code,user)
      image_server_group = ImageServerGroup.where(:id=>group_id)
      ImageServerImage.update_image_status(image_server_group,'cs')

      UserMailer.notify_cc_assignment_complete(user,group_id,chapman_code).deliver_now
    end

    def find_by_source_ids(id)
      where(:source_id => {'$in'=>id.keys})
    end

    def group_ids_by_syndicate(syndicate,type=nil)
      gid = []
      @group_id = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

      case type
      when 't'
        scope = ['u','ar','a','bt','ts','br','rs','r','cs','c']
      when 'r'
        scope = ['u','ar','a','bt','ts','t','br','rs','cs','c']
      end

      match_image_group = ImageServerGroup.where(:syndicate_code=>syndicate, 'summary.status'=>{'$nin'=>['c']})
      if type == 't' || type == 'r'
        filtered_group_id = Array.new

        group_summary = match_image_group.pluck(:id, :summary)
        group_status = Hash.new{|h,k| h[k]=[]}.tap{|h| group_summary.each{|k,v| h[k] << v[:status]}}

        group_status.each{|g_id,status| filtered_group_id << g_id if (scope & status.flatten).empty?}

        match_image_group = ImageServerGroup.where(:id=>{'$in'=>filtered_group_id})
      end

      if match_image_group.first.nil?
        source, g_id, @group_id = nil, [], []
      else
        image_server_group = match_image_group.pluck(:id, :source_id, :group_name, :syndicate_code, :assign_date, :number_of_images)
        group_id = Hash.new{|h,k| h[k]=[]}.tap{|h| image_server_group.each{|k,v1,v2,v3,v4,v5| h[k] << v1 << v2 << v3 << v4 << v5}}

        match_place = match_image_group.distinct(:place_id)
        place_id = Place.where(:id=>{'$in'=>match_place}).pluck(:id, :place_name).to_h

        church_id, register_id, source, source_id = prepare_location_id_hash(place_id)

        group_id.each do |key,value|
          (place_name, church_name, register_type, sourceId, sourceName, group_name, syndicate, assign_date, number_of_images) = prepare_gid_array_value(place_id, church_id, register_id, source_id, value)

          gid << [key, place_name, church_name, register_type, sourceName, sourceId, group_name, syndicate, assign_date, number_of_images]

          @group_id[place_name][church_name][register_type][sourceName][group_name] = key
        end
        g_id = gid.sort_by {|a,b,c,d,e,f,g,h,i,j| [b,c,d,e,g ? 0:1,g.downcase]}
      end

      return source, g_id, @group_id
    end

    def group_ids_for_available_assignment_by_county(chapman_code)
      gid = []
      @group_id = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

      place_id = Place.chapman_code(chapman_code).pluck(:id, :place_name).to_h
      church_id, register_id, source, source_id = prepare_location_id_hash(place_id)

      image_server_group = ImageServerGroup.find_by_source_ids(source_id).where("summary.status"=>{'$in'=>['u']}).pluck(:id, :source_id, :group_name, :syndicate_code, :assign_date, :number_of_images)
      group_id = Hash.new{|h,k| h[k]=[]}.tap{|h| image_server_group.each{|k,v1,v2,v3,v4,v5| h[k] << v1 << v2 << v3 << v4 << v5}}

      group_id.each do |key,value|
        (place_name, church_name, register_type, sourceId, sourceName, group_name, syndicate, assign_date, number_of_images) = prepare_gid_array_value(place_id, church_id, register_id, source_id, value)

        gid << [key, place_name, church_name, register_type, sourceName, sourceId, group_name, syndicate, assign_date, number_of_images]

        @group_id[place_name][church_name][register_type][sourceName][group_name] = key
      end
      g_id = gid.sort_by { |a,b,c,d,e,f,g,h,i,j| [b,c,d,e,g ? 0:1,g.downcase] }

      return source, g_id, @group_id
    end

    def group_ids_sort_by_syndicate(chapman_code)
      gid = []
      @syndicate = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

      place_id = Place.chapman_code(chapman_code).pluck(:id, :place_name).to_h
      church_id, register_id, source, source_id = prepare_location_id_hash(place_id)

      image_server_group = ImageServerGroup.find_by_source_ids(source_id).pluck(:id, :source_id, :group_name, :syndicate_code, :assign_date, :number_of_images)
      group_sort_by_syndicate = image_server_group.sort_by {|a,b,c,d,e,f| [b,d ? 0 : 1, d]}

      group_id = Hash.new{|h,k| h[k]=[]}.tap{|h| group_sort_by_syndicate.each{|k,v1,v2,v3,v4,v5| h[k] << v1 << v2 << v3 << v4 << v5}}

      group_id.each do |key,value|
        (place_name, church_name, register_type, sourceId, sourceName, group_name, syndicate, assign_date, number_of_images) = prepare_gid_array_value(place_id, church_id, register_id, source_id, value)

        gid << [syndicate, key, place_name, church_name, register_type, sourceName, sourceId, group_name, assign_date, number_of_images]

        @syndicate[syndicate][place_name][church_name][register_type][sourceName][group_name] = key
      end
      g_id = gid.sort_by {|a,b,c,d,e,f,g,h,i,j| [a ? 0:1, a.to_s.downcase,c,d,e,f]}

      return source, g_id, @syndicate
    end

    def group_ids_sort_by_place(chapman_code, allocation_filter=nil)
      gid = []
      @group_id = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

      place_id = Place.chapman_code(chapman_code).pluck(:id, :place_name).to_h
      church_id, register_id, source, source_id = prepare_location_id_hash(place_id)

      case allocation_filter
      when 'all'
        image_server_group = ImageServerGroup.find_by_source_ids(source_id).pluck(:id, :source_id, :group_name, :syndicate_code, :assign_date, :number_of_images)
      when 'allocate request'
        image_server_group = ImageServerGroup.find_by_source_ids(source_id).where('summary.status'=>{'$in'=>['ar']}).pluck(:id, :source_id, :group_name, :syndicate_code, :assign_date, :number_of_images)
      when 'unallocate'
        image_server_group = ImageServerGroup.find_by_source_ids(source_id).where('summary.status'=>{'$in'=>['u']}).pluck(:id, :source_id, :group_name, :syndicate_code, :assign_date, :number_of_images)
      when 'completion_submitted'
        image_server_group = ImageServerGroup.find_by_source_ids(source_id).where('summary.status'=>{'$in'=>['cs']}).pluck(:id, :source_id, :group_name, :syndicate_code, :assign_date, :number_of_images)
      else
        image_server_group = ImageServerGroup.find_by_source_ids(source_id).pluck(:id, :source_id, :group_name, :syndicate_code, :assign_date, :number_of_images)
      end

      if image_server_group.nil?
        source, g_id, @group_id = nil, nil, nil
      else
        group_id = Hash.new{|h,k| h[k]=[]}.tap{|h| image_server_group.each{|k,v1,v2,v3,v4,v5| h[k] << v1 << v2 << v3 << v4 << v5}}

        group_id.each do |key,value|
          (place_name, church_name, register_type, sourceId, sourceName, group_name, syndicate, assign_date, number_of_images) = prepare_gid_array_value(place_id, church_id, register_id, source_id, value)

          gid << [key, place_name, church_name, register_type, sourceName, sourceId, group_name, syndicate, assign_date, number_of_images]

          @group_id[place_name][church_name][register_type][sourceName][group_name] = key
        end
        g_id = gid.sort_by {|a,b,c,d,e,f,g,h,i,j| [b,c,d,e,g ? 0:1,g.downcase]}
      end

      return source, g_id, @group_id
    end

    def group_list_by_status(source_id,status)
      # get hash key=image_server_group_id, val=ig, sorted by ig
      ig_array = ImageServerGroup.where(:source_id=>source_id, :number_of_images=>{'$nin'=>[nil,'',0]}, :"summary.status"=>{'$in'=>status}).pluck(:id, :group_name)
      @group_name = Hash[ig_array.map {|key,value| [key,value]}]

      return @group_name
    end

    def id(id)
      where(:id => id)
    end

    def image_server_groups_by_user_role(user_role,source_id,syndicate=nil)
      if user_role == 'manage syndicate'
        image_server_group = ImageServerGroup.where(:source_id=>source_id, :syndicate_code=>syndicate, 'summary.status'=>{'$nin'=>['c']}).sort_by{|x| x.group_name.downcase} if !syndicate.nil?
      else
        image_server_group = ImageServerGroup.where(:source_id=>source_id).sort_by{|x| x.group_name.downcase}
      end

      return image_server_group
    end

    def initialize_all_images_status_under_image_group(group_id,status)
      ImageServerImage.where(:image_server_group_id=>group_id).update_all(:status=>status)
      ImageServerGroup.where(:id=>group_id).update_all('summary.status'=>[status])
    end

    def initialize_all_images_status_under_source(source_id,status)
      image_server_group_ids = ImageServerGroup.source_id(source_id).pluck(:id)
      ImageServerImage.where(:image_server_group_id=>{'$in'=>image_server_group_ids}).update_all(:status=>status)
      ImageServerGroup.where(:id=>{'$in'=>image_server_group_ids}).update_all('summary.status'=>[status])
    end

    def prepare_location_id_hash(place_id)
      church = Church.find_by_place_ids(place_id).pluck(:id, :place_id, :church_name)
      church_id = Hash.new{|h,k| h[k]=[]}.tap{|h| church.each{|k,v1,v2| h[k] << v1 << v2}}

      register = Register.find_by_church_ids(church_id).pluck(:id, :church_id, :register_type)
      register_id = Hash.new{|h,k| h[k]=[]}.tap{|h| register.each{|k,v1,v2| h[k] << v1 << v2}}

      source = Source.find_by_register_ids(register_id).pluck(:id, :register_id, :source_name)
      source_id = Hash.new{|h,k| h[k]=[]}.tap{|h| source.each{|k,v1,v2| h[k] << v1 << v2}}

      return church_id, register_id, source, source_id
    end

    def prepare_gid_array_value(place_id,church_id,register_id,source_id,val)
      place_name = place_id[church_id[register_id[source_id[val[0]][0]][0]][0]]
      church_name = church_id[register_id[source_id[val[0]][0]][0]][1]
      register_type = register_id[source_id[val[0]][0]][1]
      sourceId = source_id[val[0]][0]
      sourceName = source_id[val[0]][1]
      group_name = val[1]
      syndicate = val[2]
      assign_date = val[3]
      number_of_images = val[4]

      return place_name,church_name,register_type,sourceId,sourceName,group_name,syndicate,assign_date,number_of_images
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

    def update_allocate_request(params)
      group_list = []
      params[:custom_field].each { |x| group_list << BSON::ObjectId.from_string(x) unless x=='0' }

      number_of_images = ImageServerGroup.calculate_image_numbers(group_list)

      group_list.each do |x|
        @image_server_group = ImageServerGroup.where(:id=>x)
        @image_server_group.update_all(:syndicate_code=>params[:syndicate_code],
                                       :assign_date=>Time.now.iso8601,
                                       :number_of_images=>number_of_images[x])

        ImageServerImage.where(:image_server_group_id=>x, :status=>{'$in'=>['u','',nil]}).update_all(:status=>'a')
        ImageServerImage.refresh_src_dest_group_summary(@image_server_group)
      end

      return @image_server_group
    end

    def update_edit_request(image_server_group,params)
      params[:number_of_images] = ImageServerImage.image_server_group_id(image_server_group.id).count
      params[:assign_date] = Time.now.iso8601 if !params[:syndicate_code].nil? && (params[:syndicate_code] != params[:orig_syndicate_code])

      attribute_params = clean_params_before_update(params)

      image_server_group.update_attributes(attribute_params)
    end

    def update_image_group_summary(difficulty,status,transcriber,reviewer,count)
      group = self.first

      group.summary[:difficulty] = difficulty
      group.summary[:status] = status
      group.summary[:transcriber] = transcriber
      group.summary[:reviewer] = reviewer
      group.number_of_images = count if !count.nil?

      group.save
    end

    def update_image_and_group_for_put_request(old_status,new_status,user=nil)
      case new_status
      when 'a'
        self.update(:assign_date=>Time.now.iso8601)
        ig = self.first
        ig.update_attributes(syndicate_code: ig.allocation_requested_through_syndicate)
        UserMailer.notify_sc_allocate_request_rejection(user,ig.group_name,ig.syndicate_code,'allocate').deliver_now

        flash_notice = 'Image Group successfully allocated'

      when 'u'
        self.update(:syndicate_code=>'', :assign_date=>nil)
        case old_status
        when 'a'
          flash_notice = 'Unallocate of Image Group was successful'
        when 'ar'
          ig = self.first
          UserMailer.notify_sc_allocate_request_rejection(user,ig.group_name,ig.syndicate_code,'reject').deliver_now

          flash_notice = 'successfully rejected Image Group allocate request'
        end

      when 'c'
        flash_notice = 'Image Group is marked as complete'
      end

      ImageServerImage.where(:image_server_group_id=>self.first.id).update_all(:status=>new_status)
      ImageServerImage.refresh_src_dest_group_summary(self)

      return flash_notice
    end

    def update_initialize_request(params)
      # params[:custom_field] = array of group ids from initialize image groups (image group index)
      # params[:custom_field] = group id from initialize image group (image group show)
      Array(params[:custom_field]).each do |x|
        @image_server_group = ImageServerGroup.id(x).first
        ImageServerGroup.initialize_all_images_status_under_image_group(x, params[:initialize_status])
      end

      return @image_server_group
    end

    def update_put_request(params, userid)
      image_server_group = ImageServerGroup.id(params[:id])
      logger.info 'update put request'
      logger.info image_server_group.first
      case params[:type]
      when 'allocate accept'
        flash_message = image_server_group.update_image_and_group_for_put_request('ar','a',userid)
      when 'allocate reject'
        flash_message = image_server_group.update_image_and_group_for_put_request('ar','u',userid)
      when 'unallocate'
        flash_message = image_server_group.update_image_and_group_for_put_request('a','u')
      when 'complete'
        if params[:completed_groups].nil?
          flash_message = image_server_group.update_image_and_group_for_put_request('r','c')
        else
          completed_groups = params[:completed_groups]
          completed_groups.each do |group_id|
            image_server_group = ImageServerGroup.id(group_id)
            flash_message = image_server_group.update_image_and_group_for_put_request('r','c')
          end
        end
      end

      return flash_message
    end
  end

  def create_upload_images_url(userid)
    source = self.source
    register = source.register
    church = register.church
    place = self.place
    URI.escape(Rails.application.config.image_server + 'manage_freereg_images/upload_images?chapman_code=' + place.chapman_code + '&place=' + place.place_name + '&church=' + church.church_name + '&register_type=' + register.register_type  + '&register=' + register.id + '&folder_name=' + source.folder_name + '&userid=' + userid + '&group_id=' + self.id + '&image_server_group_name=' + self.group_name + '&image_server_access=' + Rails.application.config.image_server_access)
  end

  def determine_ownership
    location = []
    source = self.source
    register = source.register if source.present?
    church = register.church if register.present?
    place = church.place if church.present?
    if place.present?
      location[0] = register.register_type
      location[1] = church.church_name
      location[2] = place.place_name
      location[3] = place.county
    end
    location
  end

  def process_uploaded_images(param)
    process = true
    message = ''
    uploaded_file_names = param[:files_uploaded].split('/ ')
    uploaded_file_names.each do |file_name|
      image = ImageServerImage.create(image_server_group_id: id, image_file_name: file_name, status: 'u') if ImageServerImage.where(image_server_group_id: id, image_file_name: file_name).first.blank?
    end
    number_of_images = self.image_server_images.count
    self.update_attribute(:number_of_images, number_of_images)
    [process, message]
  end

  def self.unallocated_groups_count
    where('summary.status'=>{'$in'=>['u']}).count
  end
end
