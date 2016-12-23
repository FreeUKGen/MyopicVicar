module Refinery
  module CountyPages
    module Admin
      class CountyPagesController < ::Refinery::AdminController

        crudify :'refinery/county_pages/county_page',
          :title_attribute => 'name',
          :xhr_paging => true


        def county_page_params
          p "overridinf"
          params.require(:county_page).permit!
        end

      end
    end
  end
end
