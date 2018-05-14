class Gap
  include Mongoid::Document

  field :start_date, type: String
  field :end_date, type: String
  field :reason, type: String
  field :note, type: String

  belongs_to :place
  belongs_to :source # only has a value if the gap_type is UNTRANSCRIBED
end
