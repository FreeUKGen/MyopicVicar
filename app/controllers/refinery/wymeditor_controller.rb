module Refinery
  class WymeditorController < ActionController::Base

    def wymiframe

      p "rendering view"
      render :template => "/refinery/wymiframe", :layout => false
    end

  end
end
