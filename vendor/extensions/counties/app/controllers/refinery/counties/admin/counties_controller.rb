module Refinery
  module Counties
    module Admin
      class CountiesController < ::Refinery::AdminController

        crudify :'refinery/counties/county',
                :title_attribute => 'county',
                :xhr_paging => true

      end
    end
  end
end
