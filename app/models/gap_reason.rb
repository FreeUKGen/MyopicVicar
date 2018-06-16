class GapReason
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short

  field :reason, type: String 
  field :notes, type: String 

  class << self
    def id(id)
      where(:id => id)
    end
  end
end
 
