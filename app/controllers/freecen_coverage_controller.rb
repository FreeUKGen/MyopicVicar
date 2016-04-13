class FreecenCoverageController < ApplicationController
  require 'chapman_code'
  require 'freecen_piece'
  skip_before_filter :require_login

  def index
    # @all_pieces = FreecenCoverage.get_index_stats
    # Since get_index_stats is a bit slow (a couple of seconds), cache the
    # result so subsequent hits will be faster

    # TODO: cache for longer time and do Rails.cache.delete when updates done
    # or records/parms added/deleted/updated
    @all_pieces = Rails.cache.fetch("freecen_coverage_index", :expires_in => 5.minutes) do
      FreecenCoverage.get_index_stats
    end
  end

  def show
    @chapman_code = params[:chapman_code]
    @county = ChapmanCode.name_from_code(@chapman_code) if !@chapman_code.nil?
    if @county.nil? 
      redirect_to freecen_coverage_path
    end
    @county_pieces = FreecenCoverage.get_county_coverage(@chapman_code)
  end

end
