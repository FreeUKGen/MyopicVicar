class Gap
  include Mongoid::Document
  
  module Reason
    UNTRANSCRIBED='u'
    DESTROYED='d'
    REFUSAL='r'
    
    ALL_REASONS = [UNTRANSCRIBED, DESTROYED, REFUSAL]
  end


  field :start_date, type: String
  field :end_date, type: String
  field :reason, type: String
  validates_inclusion_of :reason, :in => Reason::ALL_REASONS
  field :note, type: String
  field :url, type: String
  belongs_to :place
  belongs_to :source # only has a value if the gap_type is UNTRANSCRIBED
end
