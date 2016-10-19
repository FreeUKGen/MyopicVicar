class Page
  include Mongoid::Document
  
  module Difficulty
    EASY='e'
    INTERMEDIATE='i'
    HARD='h'
    
    ALL_DIFFICULTIES = [EASY, INTERMEDIATE, HARD]
  end

  module Status
    UNTRANSCRIBED = 'u'
    IN_PROGRESS = 'p'
    TRANSCRIBED = 't'
    REVIEWED = 'r'
    
    ALL_STATUSES = [UNTRANSCRIBED, IN_PROGRESS, TRANSCRIBED, REVIEWED]
  end
  
  field :order, type: Integer
  field :difficulty, type: String
  validates_inclusion_of :difficulty, :in => Difficulty::ALL_DIFFICULTIES+[nil]
  field :status, type: String, default: Status::UNTRANSCRIBED
  validates_inclusion_of :status, :in => Status::ALL_STATUSES
  field :file_name, type: String # handle for finding the image on our image servers
  field :external_url, type: String # URL for the page if it lives elsewhere
  belongs_to :source
end
