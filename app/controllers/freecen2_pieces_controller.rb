class Freecen2PiecesController < ApplicationController
  require 'freecen_constants'

  def chapman_year_index
    get_user_info_from_userid
    @chapman_code = params[:chapman_code]
    @year = params[:year]
    @freecen2_pieces = Freecen2Piece.chapman_code(@chapman_code).year(@year).order_by(year: 1, piece_number: 1).all
    session.delete(:freecen2_civil_parish)
    session.delete(:current_page_civil_parish)
    @type = 'year_index'
  end

  def destroy
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No piece identified') && return if params[:id].blank?

    get_user_info_from_userid
    @freecen2_piece = Freecen2Piece.where('_id' => params[:id]).first
    if @freecen2_piece.present?
      @freecen2_piece.delete
      flash[:notice] = 'Piece destroyed'
    else
      flash[:notice] = 'Piece does not exist'
    end
    redirect_to freecen2_pieces_path
  end


  def district_place_name
    get_user_info_from_userid
    @chapman_code = session[:chapman_code]
    @freecen2_pieces = Freecen2Piece.district_place_name(@chapman_code)
    @type = 'district_place_name'
  end


  def edit
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No piece identified') && return if params[:id].blank?

    get_user_info_from_userid
    @freecen2_piece = Freecen2Piece.where('_id' => params[:id]).first
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No piece found') && return if @freecen2_piece.blank?

    session[:freecen2_piece] = @freecen2_piece.name
    @freecen2_place = @freecen2_piece.freecen2_place
    @freecen2_place = @freecen2_place.present? ? @freecen2_place.place_name : ''
    @freecen2_pieces = @freecen2_piece.piece_names
    @places = @freecen2_piece.piece_place_names
    @type = params[:type]
  end

  def index
    get_user_info_from_userid
    if session[:chapman_code].present?
      @census = Freecen::CENSUS_YEARS_ARRAY
      @chapman_code = session[:chapman_code]
      @freecen2_pieces_distinct = Freecen2Piece.chapman_code(session[:chapman_code]).distinct(:name).sort_by(&:downcase)
      @freecen2_pieces_distinct = Kaminari.paginate_array(@freecen2_pieces_distinct).page(params[:page]).per(50)
      @type = 'index'
      session[:current_page_piece] = @freecen2_pieces_distinct.current_page if @freecen2_pieces_distinct.present?
      session.delete(:freecen2_piece)
    else
      redirect_back(fallback_location: new_manage_resource_path, notice: 'No chapman code') && return
    end
  end

  def index_district
    get_user_info_from_userid
    if session[:chapman_code].present?
      @chapman_code = session[:chapman_code]
      @freecen2_district = Freecen2District.find_by(id: params[:freecen2_district_id])
      @type = params[:type]
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
    @type = 'missing_place_index'
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
    @type = params[:type]
    session[:freecen2_piece] = @freecen2_piece.name
  end

  def update
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No information in the update') && return if params[:id].blank? || params[:freecen2_piece].blank?

    @freecen2_piece = Freecen2Piece.where('_id' => params[:id]).first
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Piece not found') && return if @freecen2_piece.blank?

    old_freecen2_place = @freecen2_piece.freecen2_place_id
    old_piece_name = @freecen2_piece.name
    params[:freecen2_piece][:freecen2_place_id] = @freecen2_piece.piece_place_id(params[:freecen2_piece][:freecen2_place_id])
    @type = params[:freecen2_piece][:type]
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
