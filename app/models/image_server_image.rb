class ImageServerImage
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
    Unallocated = 'u'
    Allocated = 'a'
    In_progress = 'ip'
    Transcribed = 't'
    In_review = 'ir'
    Reviewed = 'r'
    Complete = 'c'
    Error = 'e'

    ARRAY_ALL = ['u', 'a', 'ip', 't', 't', 'ir', 'r', 'c', 'e']
    ALL_STATUSES = {'u'=>'Unallocated', 'a'=>'Allocated', 'ip'=>'In_progress', 't'=>'Transcribed', 'ir'=>'In_review', 'r'=>'Reviewed', 'c'=>'Complete', 'e'=>'Error'}
  end

  field :image_name, type: String
  field :seq, type: String
  field :start_date, type: String
  field :end_date, type: String
  field :transcriber, type: Array
  field :reviewer, type: Array
  field :difficulty, type: String
#  validates_inclusion_of :difficulty, :in => Difficulty::ALL_DIFFICULTIES+[nil]
  field :status, type: String, default: nil
#  validates_inclusion_of :status, :in => Status::ALL_STATUSES
  field :image_file_name, type: String
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
      seq = ImageServerImage.where(:image_server_group_id=>group_id, :status=>'a').pluck(:id, :image_name, :seq)
      image_list = Hash.new{|h,k| h[k]=[]}.tap{|h| seq.each{|k,v,w| h[k]=v+'_'+w}}

      image_list
    end

    def get_image_list(group_id,status_list)
      seq = ImageServerImage.where(:image_server_group_id=>group_id, :status=>{'$in'=>status_list}).pluck(:id, :image_name, :seq)

      #myseq = Hash.new{|h,k| h[k] = []}
      image_list = Hash.new{|h,k| h[k]=[]}.tap{|h| seq.each{|k,v,w| h[k]=v+'_'+w}}
      #image_list = Hash[seq.map {|k,v| [k, myseq[k] = v[0].to_s+'_'+k[1].to_s]}]   #get new hash key=image_name:seq, val=image_name_seq
      image_list
    end

    def get_in_progress_image_list(assignment_id)
      seq = ImageServerImage.where(:assignment_id=>assignment_id, :status=>'ip').pluck(:id, :image_name, :seq)
      image_list = Hash.new{|h,k| h[k]=[]}.tap{|h| seq.each{|k,v,w| h[k]=v+'_'+w}}

      image_list
    end

    def get_in_review_image_list(assignment_id)
      seq = ImageServerImage.where(:assignment_id=>assignment_id, :status=>'ir').pluck(:id, :image_name, :seq)
      image_list = Hash.new{|h,k| h[k]=[]}.tap{|h| seq.each{|k,v,w| h[k]=v+'_'+w}}

      image_list
    end

    def get_sorted_group_name(source_id)    # get hash key=image_server_group_id, val=ig, sorted by ig
      ig_array = ImageServerGroup.where(:source_id=>source_id).pluck(:id, :group_name)
      group_name = Hash[ig_array.map {|key,value| [key,value]}]
      group_name = group_name.sort_by{|key,value| value.downcase}.to_h

      group_name
    end

    def get_transcribed_image_list(group_id)
      seq = ImageServerImage.where(:image_server_group_id=>group_id, :status=>'t').pluck(:id, :image_name, :seq)
      image_list = Hash.new{|h,k| h[k]=[]}.tap{|h| seq.each{|k,v,w| h[k]=v+'_'+w}}

      image_list
    end

    def id(id)
      where(:id => id)
    end

    def image_server_group_id(id)
      where(:image_server_group_id => id)
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
end
