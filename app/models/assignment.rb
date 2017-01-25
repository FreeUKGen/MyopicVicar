class Assignment
  include Mongoid::Document
  field :instructions, type: String
  field :chapman_code, type: String
  field :status, type: String, default: Page::Status::UNTRANSCRIBED
  validates_inclusion_of :status, :in => Page::Status::ALL_STATUSES
  belongs_to :source
  belongs_to :userid_detail
  
  # TODO: Should an assignment be associated with pages at the record level?
end
