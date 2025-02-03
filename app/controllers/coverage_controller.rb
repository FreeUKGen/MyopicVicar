class CoverageController < ApplicationController

  def index
    @coverage = Coverage.all
  end
end

