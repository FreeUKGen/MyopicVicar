module Refinery
  module Counties
    class CountiesController < ::ApplicationController

      before_filter :find_all_counties
      before_filter :find_page

      def index
        # you can use meta fields from your model instead (e.g. browser_title)
        # by swapping @page for @county in the line below:
        present(@page)
      end

      def show
        @county = County.find(params[:id])

        # you can use meta fields from your model instead (e.g. browser_title)
        # by swapping @page for @county in the line below:
        present(@page)
      end

    protected

      def find_all_counties
        @counties = County.order('position ASC')
      end

      def find_page
        @page = ::Refinery::Page.where(:link_url => "/counties").first
      end

    end
  end
end
