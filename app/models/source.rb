class Source
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  
  field :source_name, type: String
  field :notes, type: String
  field :start_date, type: String
  field :end_date, type: String

  field :original_form, type: Hash, default: {}
  field :original_owner, type: String
  field :creating_institution, type: String
  field :holding_institution, type: String
  field :restrictions_on_use_by_creating_institution, type: String
  field :restrictions_on_use_by_holding_institution, type: String
  field :open_data, type: Boolean, default: true
  field :url, type: String #if the source is locatable online, this is the URL for the top-level (not single-page) webpage for it

  belongs_to :register, index: true
  has_many :image_server_groups, foreign_key: :source_id, :dependent=>:restrict # includes transcripts, printed editions, and microform, and digital versions of these

  accepts_nested_attributes_for :image_server_groups, :reject_if => :all_blank
  attr_accessor :propagate

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
