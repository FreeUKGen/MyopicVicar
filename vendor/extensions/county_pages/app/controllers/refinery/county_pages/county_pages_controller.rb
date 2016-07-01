module Refinery
  module CountyPages
    class CountyPagesController < ::ApplicationController
      skip_before_filter :require_login
      before_filter :find_all_county_pages
      before_filter :find_page

      def index
        # you can use meta fields from your model instead (e.g. browser_title)
        # by swapping @page for @county_page in the line below:
        present(@page)
      end

      def show
        @county_page = CountyPage.find(params[:id])

        # you can use meta fields from your model instead (e.g. browser_title)
        # by swapping @page for @county_page in the line below:
        present(@page)
      end

    protected

      def find_all_county_pages
        @county_pages = CountyPage.order('position ASC')
      end

      def find_page
        @page = ::Refinery::Page.where(:link_url => "/county_pages").first
      end

    end
  end
end
