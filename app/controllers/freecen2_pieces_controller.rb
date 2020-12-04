class Freecen2PiecesController < ApplicationController
  require 'freecen_constants'

  def chapman_year_index
    get_user_info_from_userid
    @chapman_code = session[:chapman_code]
    @year = params[:year]
    @freecen2_pieces = Freecen2Piece.chapman_code(@chapman_code).year(@year).order_by(year: 1, piece_number: 1).all
    session.delete(:freecen2_civil_parish)
    session.delete(:current_page_civil_parish)
    session[:type] = 'piece_year_index'
  end

  def destroy
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No district identified') && return if params[:id].blank?

    @freecen2_piece = Freecen2Piece.find_by(id: params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No district found') && return if @freecen2_piece.blank?

    success = @freecen2_piece.destroy
    flash[:notice] = success ? 'Piece deleted' : 'Piece deletion failed'
    redirect_to freecen2_pieces_path
  end

  def district_place_name
    get_user_info_from_userid

    @chapman_code = session[:chapman_code]
    @freecen2_pieces = Freecen2Piece.district_place_name(@chapman_code)
    session[:type] = 'piece_district_place_name'
  end

  def edit
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No piece identified') && return if params[:id].blank?

    get_user_info_from_userid
    @freecen2_piece = Freecen2Piece.where('_id' => params[:id]).first
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No piece found') && return if @freecen2_piece.blank?

    session[:freecen2_piece] = @freecen2_piece.name
    @chapman_code = session[:chapman_code]
    @freecen2_place = @freecen2_piece.freecen2_place
    @freecen2_place = @freecen2_place.present? ? @freecen2_place.place_name : ''
    @freecen2_pieces = @freecen2_piece.piece_names
    @places = @freecen2_piece.piece_place_names
    @type = session[:type]
  end

  def full_index
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No Chapman code') && return if session[:chapman_code].blank?

    get_user_info_from_userid
    @census = Freecen::CENSUS_YEARS_ARRAY
    @chapman_code = session[:chapman_code]
    @freecen2_pieces_distinct = Freecen2Piece.chapman_code(session[:chapman_code]).distinct(:name).sort_by(&:downcase)
    @freecen2_pieces_distinct = Kaminari.paginate_array(@freecen2_pieces_distinct).page(params[:page]).per(100)
    session[:current_page_piece] = @freecen2_pieces_distinct.current_page if @freecen2_pieces_distinct.present?
    session[:type] = 'piece_index'
  end

  def index
    get_user_info_from_userid
    if session[:chapman_code].present?
      @census = Freecen::CENSUS_YEARS_ARRAY
      @chapman_code = session[:chapman_code]
      session[:type] = 'piece'
      session.delete(:freecen2_piece)
      session.delete(:current_page_piece)
    else
      redirect_back(fallback_location: new_manage_resource_path, notice: 'No chapman code') && return
    end
  end

  def index_district
    get_user_info_from_userid
    if session[:chapman_code].present?
      @chapman_code = session[:chapman_code]
      @freecen2_district = Freecen2District.find_by(id: params[:freecen2_district_id])
      @type = session[:type]
      @freecen2_pieces = Freecen2Piece.where(freecen2_district_id: @freecen2_district.id).all.order_by(name: 1)
      @year = @freecen2_district.year
    else
      redirect_back(fallback_location: new_manage_resource_path, notice: 'No chapman code') && return
    end
  end

  def index_district_year
    get_user_info_from_userid
    if session[:chapman_code].present?
      @chapman_code = session[:chapman_code]
      @type = session[:type]
      @totals_pieces = Freecen2Piece.county_district_year_totals(params[:id])
      @grand_totals_pieces = Freecen2Piece.grand_totals(@totals_pieces)
    else
      redirect_back(fallback_location: new_manage_resource_path, notice: 'No chapman code') && return
    end
  end

  def missing_place
    get_user_info_from_userid
    @chapman_code = session[:chapman_code]
    @freecen2_pieces = Freecen2Piece.missing_places(@chapman_code)
    session[:type] = 'missing_piece_place_index'
  end

  def selection_by_name
    @chapman_code = session[:chapman_code]
    get_user_info_from_userid
    @freecen2_piece = Freecen2Piece.new
    @options = {}
    Freecen2Piece.chapman_code(@chapman_code).order_by(number: 1, year: 1).each do |piece|
      @options["#{piece.number} (#{piece.year}) (#{piece.name})"] = piece._id
    end
    @location = 'location.href= "/freecen2_pieces/" + this.value'
    @prompt = 'Select Sub district (Piece)'
    session[:type] = 'piece_name'
    render '_form_for_selection'
  end

  def selection_by_year
    @chapman_code = session[:chapman_code]
    get_user_info_from_userid
    @freecen2_piece = Freecen2District.new
    @options = Freecen::CENSUS_YEARS_ARRAY
    @location = 'location.href= "/freecen2_pieces/chapman_year_index/?year=" + this.value'
    @prompt = 'Select Year'
    session[:type] = 'piece_year'
    render '_form_for_selection'
  end

  def select_new_county
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No year identified') && return unless Freecen::CENSUS_YEARS_ARRAY.include?(params[:year])

    @county = ''
    @year = params[:year]
    year_pieces = Freecen2Piece.only(:chapman_code).where('year' => @year).entries
    existing_year_counties = []
    if year_pieces.present?
      year_pieces.each do |yp|
        existing_year_counties << yp[:chapman_code]
      end
    end
    @year_counties = (ChapmanCode.values - existing_year_counties).sort
  end

  def show
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No piece identified') && return if params[:id].blank?

    get_user_info_from_userid
    @freecen2_piece = Freecen2Piece.find_by(id: params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No piece found') && return if @freecen2_piece.blank?

    @place = @freecen2_piece.freecen2_place
    @chapman_code = session[:chapman_code]
    @type = session[:type]
    session[:freecen2_piece] = @freecen2_piece.name
  end

  def update
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No information in the update') && return if params[:id].blank? || params[:freecen2_piece].blank?

    @freecen2_piece = Freecen2Piece.where('_id' => params[:id]).first
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Piece not found') && return if @freecen2_piece.blank?

    old_freecen2_place = @freecen2_piece.freecen2_place_id
    old_piece_name = @freecen2_piece.name
    params[:freecen2_piece][:freecen2_place_id] = @freecen2_piece.piece_place_id(params[:freecen2_piece][:freecen2_place_id])
    @type = session[:type]
    params[:freecen2_piece].delete :type

    @freecen2_piece.update(freecen2_piece_params)
    if @freecen2_piece.errors.any?
      flash[:notice] = "The update of the civil parish failed #{@freecen2_piece.errors.full_messages}."
      redirect_back(fallback_location: edit_freecen2_piece_path(@freecen2_piece, type: @type)) && return
    else
      flash[:notice] = 'Update was successful'
      get_user_info_from_userid
      @freecen2_piece.update_tna_change_log(@user_userid)
      @freecen2_piece.reload
      @freecen2_piece.propagate_freecen2_place(old_freecen2_place, old_piece_name)
      redirect_to freecen2_piece_path(@freecen2_piece, type: @type)
    end
  end

  private

  def freecen2_piece_params
    params.require(:freecen2_piece).permit!
  end
end
