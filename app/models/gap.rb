class Gap
  include Mongoid::Document

  field :start_date, type: String
  field :end_date, type: String
  field :record_type, type: String
  validates_inclusion_of :record_type, in: RecordType::ALL_FREEREG_TYPES + ['All']
  field :reason, type: String
  field :note, type: String

  belongs_to :register, index: true
end
