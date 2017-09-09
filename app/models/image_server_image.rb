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
    ERROR = 'e'
    UNALLOCATED = 'u'
    IN_PROGRESS = 'p'
    TRANSCRIBED = 't'
    REVIEWED = 'r'

    ALL_STATUSES = {'u'=>'UNALLOCATED', 'p'=>'IN_PROGRESS', 't'=>'TRANSCRIBED', 'r'=>'REVIEWED', 'e'=>'ERROR'}
  end

  field :order, type: Integer
#  validates_inclusion_of :difficulty, :in => Difficulty::ALL_DIFFICULTIES+[nil]
  validates_inclusion_of :status, :in => Status::ALL_STATUSES
  field :external_url, type: String # URL for the image if it lives elsewhere
  field :consistency, type: Mongoid::Boolean, default: 'true'

  field :start_date, type: String
  field :end_date, type: String
  field :image_name, type: String
  field :seq, type: String
  field :status, type: String, default: nil
  field :difficulty, type: String
  field :transcriber, type: Array
  field :reviewer, type: Array
  field :notes, type: String

  belongs_to :image_server_group, index: true
  belongs_to :assignment, index: true # optional -- consider renaming as "current_assignment" or storing as an array of image_ids on an assignment record
  #has_one :page_image # kirk prefers has_many here and may be right, but the only example I can think of
  # where it makes sense to have multiple images per page(of a source) is in the case
  # of derivatives
  embeds_one :page_image

  class << self

    def id(id)
      where(:id => id)
    end

    def image_server_group_id(id)
      where(:image_server_group_id => id)
    end

  end
  
end
