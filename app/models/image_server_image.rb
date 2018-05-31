class ImageServerImage
  require 'source_property'

  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short

  field :image_file_name, type: String
  field :start_date, type: String
  field :end_date, type: String
  field :transcriber, type: Array
  field :reviewer, type: Array
  field :difficulty, type: String
#  validates_inclusion_of :difficulty, :in => Difficulty::ALL_DIFFICULTIES+[nil]
  field :status, type: String, default: nil
#  validates_inclusion_of :status, :in => Status::ALL_STATUSES
  field :notes, type: String

  field :order, type: Integer
  field :external_url, type: String # URL for the image if it lives elsewhere
  field :consistency, type: Mongoid::Boolean, default: 'true'

  belongs_to :image_server_group, index: true
  belongs_to :assignment, index: true # optional -- consider renaming as "current_assignment" or storing as an array of image_ids on an assignment record
  #has_one :page_image # kirk prefers has_many here and may be right, but the only example I can think of
  # where it makes sense to have multiple images per page(of a source) is in the case
  # of derivatives
  #embeds_one :page_image
  
  index({image_server_group_id:1,status:1},{name: "image_server_group_id_status"})
  index({image_server_group_id:1,difficulty:1},{name: "image_server_group_id_difficulty"})
  index({image_server_group_id:1,transcriber:1},{name: "image_server_group_id_transcriber"})
  index({image_server_group_id:1,reviewer:1},{name: "image_server_group_id_reviewer"})

  class << self


  def create_url(method,id,chapman_code,folder_name,image_file_name,userid)
   URI.escape(Rails.application.config.image_server + 'manage_freereg_images/' + method + '?' + 'chapman_code=' + chapman_code + '&folder_name=' + folder_name + '&image_file_name=' + image_file_name + '&userid=' + userid + '&id=' + id  + '&image_server_access=' + Rails.application.config.image_server_access)
  end
  
    def find_by_image_server_group_ids(id)
      where(:image_server_group_id => {'$in'=>id.keys})
    end

    def get_allocated_image_list(group_id)
      list = ImageServerImage.where(:image_server_group_id=>group_id, :status=>'a').pluck(:id, :image_file_name)
      image_list = Hash.new{|h,k| h[k]=[]}.tap{|h| list.each{|k,v| h[k]=v}}

      image_list
    end

    def get_group_and_image_from_group_id(group_id)
      image_server_group = ImageServerGroup.id(group_id)
      image_server_image = ImageServerImage.where(:image_server_group_id=>group_id)

      return image_server_group, image_server_image
    end

    def get_image_list(group_id,status_list)
      list = ImageServerImage.where(:image_server_group_id=>group_id, :status=>{'$in'=>status_list}).pluck(:id, :image_file_name)

      #myseq = Hash.new{|h,k| h[k] = []}
      image_list = Hash.new{|h,k| h[k]=[]}.tap{|h| list.each{|k,v| h[k]=v}}

      image_list
    end

    def get_transcriber_reassign_image_list(assignment_id)
      list = ImageServerImage.where(:assignment_id=>assignment_id, :status=>{'$in'=>['bt','ts']}).pluck(:id, :image_file_name)
      image_list = Hash.new{|h,k| h[k]=[]}.tap{|h| list.each{|k,v| h[k]=v}}

      image_list
    end

    def get_reviewer_reassign_image_list(assignment_id)
      list = ImageServerImage.where(:assignment_id=>assignment_id, :status=>{'$in'=>['br','rs']}).pluck(:id, :image_file_name)
      image_list = Hash.new{|h,k| h[k]=[]}.tap{|h| list.each{|k,v| h[k]=v}}

      image_list
    end

    def get_sorted_group_name_under_church(church_id)    # get hash key=image_server_group_id, val=ig, sorted by ig
      ig_array = ImageServerGroup.where(:church_id=>church_id).pluck(:id, :group_name)
      group_name = Hash[ig_array.map {|key,value| [key,value]}]
      group_name = group_name.sort_by{|key,value| value.downcase}.to_h

      group_name
    end

    def get_sorted_group_name_under_source(source_id)    # get hash key=image_server_group_id, val=ig, sorted by ig
      ig_array = ImageServerGroup.where(:source_id=>source_id).pluck(:id, :group_name)
      group_name = Hash[ig_array.map {|key,value| [key,value]}]
      group_name = group_name.sort_by{|key,value| value.downcase}.to_h

      group_name
    end

    def get_transcribed_image_list(group_id)
      list = ImageServerImage.where(:image_server_group_id=>group_id, :status=>'t').pluck(:id, :image_file_name)
      image_list = Hash.new{|h,k| h[k]=[]}.tap{|h| list.each{|k,v| h[k]=v}}

      image_list
    end

    def id(id)
      where(:id => id)
    end

    def image_server_group_id(id)
      where(:image_server_group_id => id)
    end

    def image_detail_access_allowed?(user,manage_user_origin,image_server_group_id,chapman_code)
      case user.person_role
        when 'syndicate_coordinator'
          @image_server_group = ImageServerGroup.id(image_server_group_id).first
          return true if user.syndicate == @image_server_group.syndicate_code
        when 'county_coordinator'
          case manage_user_origin 
            when 'manage county'
              county_coordinator = County.where(:chapman_code=>chapman_code).first.county_coordinator
              return true if user.userid == county_coordinator
            when 'manage syndicate'
              @image_server_group = ImageServerGroup.id(image_server_group_id).first
              return true if user.syndicate == @image_server_group.syndicate_code
          end
        when 'system_administrator'
          return true
      end

      return false
    end

    def refresh_image_server_group_after_assignment(image_server_group_id)
      image_server_group = ImageServerGroup.id(image_server_group_id)
      ImageServerImage.refresh_src_dest_group_summary(image_server_group)
    end

    def refresh_src_dest_group_summary(image_server_group)
      # update field summary of ImageServerGroup
      summary = image_server_group.summarize_from_image_server_image

      image_server_group.update_image_group_summary(summary[0], summary[1], summary[2], summary[3], summary[4]) if !summary.nil? && !summary.empty?
    end

    def update_image_status(image_server_group,status)
      ImageServerImage.where(:image_server_group_id=>image_server_group.first.id).update_all(:status=>status)
      refresh_src_dest_group_summary(image_server_group)
    end
  
  end # end of class methods
  
  def deletion_permitted?
    permitted = false
    permitted = true if self.status.nil? || self.status == 'u'
    permitted
  end
  
  def file_location
     group = self.image_server_group
     source = group.source 
     register = source.register 
     church = register.church 
     place = church.place 
     place.nil? ? process = false: process = true
     return process,place.chapman_code, source.folder_name, self.image_file_name
  end
  
  def location
    group = self.image_server_group
    source = group.source
    register = source.register
    return group,source,register
  end

  def url_for_delete_image_from_image_server
    image_server_group = self.image_server_group
    source = image_server_group.source
    place = image_server_group.place
    URI.escape(Rails.application.config.image_server + 'manage_freereg_images/remove_image?chapman_code=' + place.chapman_code + '&image_server_group_id=' + self.image_server_group.id + '&folder_name=' + source.folder_name + '&image_file_name=' + self.image_file_name + '&image_server_access=' + Rails.application.config.image_server_access)
  end
end
