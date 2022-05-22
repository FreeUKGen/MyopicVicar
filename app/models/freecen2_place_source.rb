class Freecen2PlaceSource
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  field :source, type: String
  validates :source, uniqueness: true

  class << self
    def id(id)
      where(id: id)
    end
  end
end
