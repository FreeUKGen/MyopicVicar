class SoftwareVersion 
  
  include Mongoid::Document
  include Mongoid::Timestamps

  #attr_accessor :date_of_update, :version
  
  field :date_of_update,  type: DateTime
  field :version, type: String
  field :type, type: String

  embeds_many :commitments

  class << self
    def id(id)
      where(:id => id)
    end
    def type(type)
      where(:type => type)
    end
    def date(date)
      where(:date_of_update => date)
    end
  end


end
