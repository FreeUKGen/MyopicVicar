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

  def graph
    @chapman_code = params[:chapman_code]
    @county = ChapmanCode.name_from_code(@chapman_code) if !@chapman_code.nil?
    @county = 'all' if 'all' == params[:chapman_code]
    @year = params[:year]
    
    redirect_to freecen_coverage_path if @county.nil?
    unless ['1841','1851','1861','1871','1881','1891','all'].include? @year
      redirect_to freecen_coverage_path
    end
    # @graph_data =FreecenCoverage.get_county_year_graph_data(@chapman_code,@year)
    @graph_type = 'ind'
    @graph_data =FreecenCoverage.get_graph_data_from_stats_file(Rails.application.config.fc1_coverage_stats,@chapman_code,@year,@graph_type)
  end

end
