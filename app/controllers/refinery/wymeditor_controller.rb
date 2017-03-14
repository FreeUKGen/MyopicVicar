module Refinery
  class WymeditorController < ActionController::Base

    def wymiframe
      render :template => "/refinery/wymiframe", :layout => false
    end

  end
end
