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
    
    def get_sorted_group_name(source_id)    
      # get hash key=image_server_group_id, val=ig, sorted by ig
      ig_array = ImageServerGroup.where(:source_id=>source_id).pluck(:id, :group_name)
      @group_name = Hash[ig_array.map {|key,value| [key,value]}]

      @group_name
    end

    def get_syndicate_list
      @syndicate_list = Syndicate.all.order_by(:syndicate_code=>1).pluck(:syndicate_code)

      @syndicate_list
    end

    def id(id)
      where(:id => id)
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

    def update_image_group_summary(move, difficulty, status, transcriber, reviewer, count)
      group = self.first

      if !difficulty.nil?
        group.summary[:difficulty] = [] if group.summary[:difficulty].nil? || difficulty.blank? || move == 1    # move=0 => populate, move=1 => move
        
        case difficulty
          when Array
            difficulty.each do |value|
              group.summary[:difficulty] << value unless group.summary[:difficulty].include?(value)
            end
          when String
            group.summary[:difficulty] << difficulty unless group.summary[:difficulty].include?(difficulty)
        end
      elsif !difficulty.blank?
        group.summary.delete(:difficulty) if group.summary.key?(:difficulty)
      end

      if !status.nil?
        group.summary[:status] = [] if group.summary[:status].nil? || status.blank? || move == 1

        case status
          when Array
            status.each do |value|
              group.summary[:status] << value unless group.summary[:status].include?(value)
            end
          when String
            group.summary[:status] << status unless group.summary[:status].include?(status)
        end
      elsif !status.blank?
        group.summary.delete(:status) if group.summary.key?(:status)
      end

      if !transcriber.nil?
        group.summary[:transcriber] = [] if group.summary[:transcriber].nil? || transcriber.blank? || move == 1
        transcriber.each do |value|
          group.summary[:transcriber] << value unless group.summary[:transcriber].include?(value)
        end
      elsif !transcriber.blank?
        group.summary.delete(:transcriber) if group.summary.key?(:transcriber)
      end

      if !reviewer.nil?
        group.summary[:reviewer] = [] if group.summary[:reviewer].nil? || reviewer.blank? || move == 1
        reviewer.each do |value|
          group.summary[:reviewer] << value unless group.summary[:reviewer].include?(value)
        end
      elsif !reviewer.blank?
        group.summary.delete(:reviewer) if group.summary.key?(:reviewer)
      end

      group.number_of_images = count if !count.nil?

      group.save
    end
    
  end
end
