class IsSource
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  
  module MsType
    PARISH_REGISTER = 'pr'
    ARCHDEACONS_TRANSCRIPT = 'at'
    BISHOPS_TRANSCRIPT = 'bt'

    ALL_TYPES = [PARISH_REGISTER, ARCHDEACONS_TRANSCRIPT, BISHOPS_TRANSCRIPT]
  end

  module Difficulty
    Learning = 'l'
    Straight_Forward_Forms = 's'
    Complicated_Forms = 'c'
    Post_1700_modern_freehand = 'p17'
    Post_1530_freehand_Secretary = 'p15s'
    Post_1530_freehand_Latin = 'p15l'
    Post_1530_freehand_Latin_Chancery = 'p15c'

    ALL_DIFFICULTIES = {'l'=>'Learning', 's'=>'Straight_Forward_Forms', 'c'=>'Complicated_Forms', 'p17'=>'Post_1700_modern_freehand', 'p15s'=>'Post_1530_freehand_Secretary',  'p15l'=>'Post_1530_freehand_Latin', 'p15c'=>'Post_1530_freehand_Latin_Chancery'}
  end

  module Status
    UNALLOCATED = 'u'
    IN_PROGRESS = 'p'
    TRANSCRIBED = 't'
    REVIEWED = 'r'

    ALL_STATUSES = {
      'u'=>'UNALLOCATED', 
      'p'=>'IN_PROGRESS', 
      't'=>'TRANSCRIBED', 
      'r'=>'REVIEWED',
      'e'=>'ERROR'
    }

    CHURCH_STATUS = {}

    REGISTER_STATUS = {
      'R4A' => 'image not transcribed yet. File on IS does not have register type on FR, create register',
      'R6A1' => 'replace register " " on FR with IS image register type(when FR has one register',
      'R6B1' => 'replace register " " on FR with IS image register type(when FR has multiple registers'
    }
  end

  field :source_name, type: String
  field :ig, type: String
  field :start_date, type: String
  field :end_date, type: String
  field :transcriber, type: String, default: nil
  field :difficulty, type: String, default: nil
  field :status, type: String

  field :digital, type: Mongoid::Boolean # is the source a digital facsimile image or a physical (paper or microform) document
  field :microform, type: Mongoid::Boolean # is the source we see a microfilm or microfiche or an original?
  field :edition, type: Mongoid::Boolean # Philimores,  Dwellys, or another printed edition from the Victorian era?
  field :ms_type, type: String
  validates_inclusion_of :ms_type, :in => MsType::ALL_TYPES+[nil]
  field :church_status, type: String
  field :register_status, type: String
  field :consistency, type: Mongoid::Boolean, default: false
  field :url, type: String # If the source is locatable online, this is the URL for the top-level (not single-page) webpage for it

  belongs_to :register, index: true
  has_many :is_images, foreign_key: :is_source_id
  has_many :gaps

  accepts_nested_attributes_for :is_images, :reject_if => :all_blank

  # TODO: name for "Great Register" vs "Baptsm" -- use RecordType?  Extend it?

  class << self

    def id(id)
      where(:id => id)
    end

    def register_id(id)
      where(:register_id => id)
    end
    
  end
  
end
