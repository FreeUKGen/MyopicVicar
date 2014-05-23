module Refinery
  module CountyPages
    module Admin
      class CountyPagesController < ::Refinery::AdminController

        crudify :'refinery/county_pages/county_page',
                :title_attribute => 'name',
                :xhr_paging => true

      end
    end
  end
end
