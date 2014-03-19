module Refinery
  module Counties
    class County < Refinery::Core::BaseModel
      self.table_name = 'refinery_counties'

      attr_accessible :county, :chapman_code, :content, :position

      validates :county, :presence => true, :uniqueness => true
    end
  end
end
