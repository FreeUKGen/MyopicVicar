class Source
  include Mongoid::Document
  #removed reference to AT BT PR etc as this is held in register
  field :source_name, type: String
  field :original_form, type: String
  field :original_owner, type: String
  field :creating_institution, type: String
  field :holding_institution, type: String
  field :restrictions_on_use_by_creating_institution, type: String
  field :restrictions_on_use_by_holding_institution, type: String
  field :open_data, type: Boolean, default: true
  field :notes, type: String
  field :start_date, type: Date
  field :end_date, type: Date
  field :url, type: String # If the source is locatable online, this is the URL for the top-level (not single-page) webpage for it
  belongs_to :place, index: true
  belongs_to :register, index: true
  has_many :pages
  has_many :gaps

  # TODO: name for "Great Register" vs "Baptsm" -- use RecordType?  Extend it?
end
