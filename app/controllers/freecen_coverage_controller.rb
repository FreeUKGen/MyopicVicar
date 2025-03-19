class FreecenCoverageController < ApplicationController
  require 'chapman_code'
  require 'freecen_piece'
  require 'freecen_constants'
  skip_before_action :require_login

  def create
    if params.present? && params[:freecen_coverage].present? && params[:freecen_coverage][:chapman_codes].present?#params[:commit] == "Select"
      @freecen_coverage = FreecenCoverage.new(freecen_coverage_params)
      @chapman_code = params[:freecen_coverage][:chapman_codes][1]
      session[:chapman_code] = @chapman_code
      if @freecen_coverage.save
        @county = ChapmanCode.name_from_code(@chapman_code)
        session[:county] = @county
        redirect_to freecen_coverage_path
        return
      else
        redirect_to new_freecen_coverage_path
      end
    elsif params.present? && params[:freecen_coverage].present? && params[:freecen_coverage][:place].present?
      redirect_to(freecen_coverage_path(params[:freecen_coverage][:place])) && return
    end
  end

  def index
    # Since get_index_stats is slow (several seconds on production), we cache
    # the result so subsequent hits will be faster. Be sure to do
    # Rails.cache.delete when updates are done (when records or parms are
    # added/deleted/updated in db)
    @all_pieces = Rails.cache.fetch("freecen_coverage_index", :expires_in => 7.days) do
      FreecenCoverage.get_index_stats
    end

    @roles=[]
    get_user_info_from_userid unless current_refinery_user.nil? # || current_refinery_user.instance_of?(Refinery::Authentication::Devise::NilUser)
    @manage_pieces = (@manager || (@roles.present? &&@roles.include?('Manage Pieces'))) ? true : false
    @editing = (@manage_pieces && session[:edit_freecen_pieces]=='edit')
  end

  def new
    @freecen_coverage = FreecenCoverage.new
    @options = ChapmanCode.add_parenthetical_codes(ChapmanCode.remove_codes(ChapmanCode::CODES))
  end


  def show
    @roles=[]
    get_user_info_from_userid unless current_refinery_user.nil? # || current_refinery_user.instance_of?(Refinery::Authentication::Devise::NilUser) #for parms
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

  def grand_totals
    @totals_pieces, @totals_pieces_online, @totals_individuals, @totals_dwellings = FreecenPiece.grand_year_totals
    @grand_totals_pieces, @grand_totals_pieces_online, @grand_totals_individuals, @grand_totals_dwellings = FreecenPiece.grand_totals(@totals_pieces, @totals_pieces_online, @totals_individuals, @totals_dwellings)
    session.delete(:manage_places)
  end

  private

  def freecen_coverage_params
    params.require(:freecen_coverage).permit!
  end

end
