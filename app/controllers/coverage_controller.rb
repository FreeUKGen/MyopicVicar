class CoverageController < ApplicationController

  skip_before_action :require_login
  def index
    @coverage = Coverage.all
  end
end

