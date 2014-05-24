module Refinery
  module CountyPages
    class CountyPage < Refinery::Core::BaseModel
      self.table_name = 'refinery_county_pages'

      attr_accessible :name, :chapman_code, :content, :position, :position

      validates :name, :presence => true, :uniqueness => true
    end
  end
end
