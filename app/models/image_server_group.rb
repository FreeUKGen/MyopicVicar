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
    IN_PROGRESS = 'p'
    TRANSCRIBED = 't'
    REVIEWED    = 'r'
    ERROR       = 'e'

    ALL_STATUSES = {'u'=>'UNALLOCATED', 'p'=>'IN_PROGRESS', 't'=>'TRANSCRIBED', 'r'=>'REVIEWED', 'e'=>'ERROR'}

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
  field :transcriber, type: Array, default: nil
  field :reviewer, type: Array, default: nil
  field :difficulty, type: Array, default: nil
  field :status, type: Array, default: nil
  field :notes, type: String

  field :church_status, type: String
  field :register_status, type: String
  field :consistency, type: Mongoid::Boolean, default: false

  belongs_to :source, index: true
  has_many :image_server_images, foreign_key: :image_server_group_id, :dependent=>:restrict # includes images
  has_many :gaps

  accepts_nested_attributes_for :image_server_images, :reject_if => :all_blank

  # TODO: name for "Great Register" vs "Baptsm" -- use RecordType?  Extend it?

  class << self

    def id(id)
      where(:id => id)
    end

    def source_id(id)
      where(:source_id => id)
    end

    def summarize_from_image_server_image(summarization=nil)
      if self.count > 0
        group_list = self.all.pluck(:id)
        properties_of_each_image = ImageServerImage.where(:image_server_group_id=>{'$in':group_list}).pluck(:image_server_group_id, :status, :difficulty, :transcriber, :reviewer)

        status_by_group_id = Hash[properties_of_each_image.group_by(&:first).collect do |key, value| [key,value.collect {|v| v[1]}] end ]
        group_status = Hash[status_by_group_id.map{|k,v| [k, v.compact.uniq]}]

        difficulty_by_group_id = Hash[properties_of_each_image.group_by(&:first).collect do |key, value| [key,value.collect {|v| v[2]}] end ]
        group_difficulty = Hash[difficulty_by_group_id.map{|k,v| [k, v.compact.uniq]}]

        transcriber_by_group_id = Hash[properties_of_each_image.group_by(&:first).collect do |key, value| [key,value.collect {|v| v[3]}] end ]
        group_transcriber = Hash[transcriber_by_group_id.map{|k,v| [k, v.flatten.compact.uniq]}]

        reviewer_by_group_id = Hash[properties_of_each_image.group_by(&:first).collect do |key, value| [key,value.collect {|v| v[4]}] end ]
        group_reviewer = Hash[reviewer_by_group_id.map{|k,v| [k, v.flatten.compact.uniq]}]

        summarization = [group_status, group_difficulty, group_transcriber, group_reviewer]
      end
      summarization
    end
    
  end
  
end
