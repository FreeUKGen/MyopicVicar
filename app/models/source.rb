class Source
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  
  module MsType
    PARISH_REGISTER = 'pr'
    ARCHDEACONS_TRANSCRIPT = 'at'
    BISHOPS_TRANSCRIPT = 'bt'

    ALL_TYPES = [PARISH_REGISTER, ARCHDEACONS_TRANSCRIPT, BISHOPS_TRANSCRIPT]
  end

  field :source_name, type: String
  field :notes, type: String

  field :digital, type: Mongoid::Boolean # is the source a digital facsimile image or a physical (paper or microform) document
  field :microform, type: Mongoid::Boolean # is the source we see a microfilm or microfiche or an original?
  field :edition, type: Mongoid::Boolean # Philimores,  Dwellys, or another printed edition from the Victorian era?
  field :ms_type, type: String
  validates_inclusion_of :ms_type, :in => MsType::ALL_TYPES+[nil]
  field :url, type: String # If the source is locatable online, this is the URL for the top-level (not single-page) webpage for it

  belongs_to :register, index: true
  has_many :image_server_groups, foreign_key: :source_id # includes transcripts, printed editions, and microform, and digital versions of these

  accepts_nested_attributes_for :image_server_groups, :reject_if => :all_blank

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
