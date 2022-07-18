class SaveEntry
  include Mongoid::Document
  include Mongoid::Timestamps
  belongs_to :userid_detail
  belongs_to :best_guess, foreign_key: 'RecordNumber', class_name: '::BestGuess'
  validates :userid_detail_id, uniqueness: {scope: :RecordNumber}
end
