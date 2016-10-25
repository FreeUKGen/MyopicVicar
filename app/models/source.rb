class Source
  include Mongoid::Document

  module MsType
    PARISH_REGISTER = 'pr'
    ARCHDEACONS_TRANSCRIPT = 'at'
    BISHOPS_TRANSCRIPT = 'bt'
    
    ALL_TYPES = [PARISH_REGISTER, ARCHDEACONS_TRANSCRIPT, BISHOPS_TRANSCRIPT]
  end


  field :digital, type: Mongoid::Boolean # is the source a digital facsimile image or a physical (paper or microform) document
  field :microform, type: Mongoid::Boolean # is the source we see a microfilm or microfiche or an original? 
  field :edition, type: Mongoid::Boolean # Philimores,  Dwellys, or another printed edition from the Victorian era?
  field :ms_type, type: String
  validates_inclusion_of :ms_type, :in => MsType::ALL_TYPES+[nil]

  field :start_date, type: Date
  field :end_date, type: Date
  field :url, type: String # If the source is locatable online, this is the URL for the top-level (not single-page) webpage for it
  belongs_to :place
  belongs_to :register 
  has_many :pages
  has_many :gaps
  
  # TODO: name for "Great Register" vs "Baptsm" -- use RecordType?  Extend it?
end
