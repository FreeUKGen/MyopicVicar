class FreecenCoverageController < ApplicationController
  require 'chapman_code'
  require 'freecen_piece'
  require 'freecen_constants'
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

    @roles=[]
    get_user_info_from_userid unless current_refinery_user.nil? || current_refinery_user.instance_of?(Refinery::Authentication::Devise::NilUser)
    @manage_pieces = (@manager || (@roles.present? &&@roles.include?('Manage Pieces'))) ? true : false
    @editing = (@manage_pieces && session[:edit_freecen_pieces]=='edit')
  end

  def show
    @roles=[]
    get_user_info_from_userid unless current_refinery_user.nil? || current_refinery_user.instance_of?(Refinery::Authentication::Devise::NilUser) #for parms
    @manage_pieces = (@manager || (@roles.present? &&@roles.include?('Manage Pieces'))) ? true : false
    session[:edit_freecen_pieces]='edit' if @manage_pieces && (params[:act]=='edit' || params[:chapman_code]=='edit')
    session.delete(:edit_freecen_pieces) if @manage_pieces && session[:edit_freecen_pieces].present? && (params[:act]=='edit_done' || params[:chapman_code]=='edit_done')
    @editing = (@manage_pieces && session[:edit_freecen_pieces]=='edit')

    @chapman_code = params[:chapman_code]
    @county = ChapmanCode.name_from_code(@chapman_code) if !@chapman_code.nil?
    if @county.nil? 
      redirect_to freecen_coverage_path
    end
    @county_pieces = FreecenCoverage.get_county_coverage(@chapman_code)
  end

  def graph
    @graph_type = params[:type]
    @chapman_code = params[:chapman_code]
    @county = ChapmanCode.name_from_code(@chapman_code) if !@chapman_code.nil?
    @county = 'All Counties' if 'all' == params[:chapman_code]
    @year = params[:year]
    
    redirect_to freecen_coverage_path if 'ind'!=@graph_type&&'pct'!=@graph_type
    redirect_to freecen_coverage_path if @county.nil?
    unless Freecen::CENSUS_YEARS_ARRAY.include?(@year) || 'all' == @year
      redirect_to freecen_coverage_path
    end
    # @graph_data =FreecenCoverage.get_county_year_graph_data(@chapman_code,@year)
    @graph_data =FreecenCoverage.get_graph_data_from_stats_file(Rails.application.config.fc1_coverage_stats,@chapman_code,@year,@graph_type)
    @year = 'All Years' if 'all'==params[:year]
  end

end
