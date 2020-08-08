class Freecen2CivilParishesController < ApplicationController
  require 'freecen_constants'

  def chapman_year_index
    get_user_info_from_userid
    @chapman_code = params[:chapman_code]
    @year = params[:year]
    @freecen2_civil_parishes = Freecen2CivilParish.chapman_code(@chapman_code).year(@year).order_by(year: 1, name: 1)
    @freecen2_piece = @freecen2_civil_parish.freecen2_piece
    @type = 'parish_year_index'
  end

  def edit
    redirect_back(fallback_location: new_manage_resource_path, notice:  'No civil parish identified') && return if params[:id].blank?

    get_user_info_from_userid
    @freecen2_civil_parish = Freecen2CivilParish.find_by(id: params[:id])
    @freecen2_place = @freecen2_civil_parish.freecen2_place
    @piece = @freecen2_civil_parish.freecen2_piece
    @chapman_code = @freecen2_civil_parish.chapman_code
    @freecen2_piece = @freecen2_civil_parish.piece_name
    places = Freecen2Place.chapman_code(@chapman_code).all.order_by(place_name: 1)
    @places = []
    places.each do |place|
      @places << place.place_name
    end
    @freecen2_civil_parish.freecen2_hamlets.build
    @freecen2_civil_parish.freecen2_townships.build
    @freecen2_civil_parish.freecen2_wards.build
    @type = params[:type]
  end

  def index
    get_user_info_from_userid
    if session[:chapman_code].present?
      @census = Freecen::CENSUS_YEARS_ARRAY
      @chapman_code = session[:chapman_code]
      @freecen2_civil_parishes_distinct = Freecen2CivilParish.chapman_code(session[:chapman_code]).distinct(:name).sort_by(&:downcase)
      @freecen2_civil_parishes_distinct = Kaminari.paginate_array(@freecen2_civil_parishes_distinct).page(params[:page]).per(50)
      @type = 'parish_index'
    else
      redirect_to manage_resources_path && return
    end
  end

  def index_for_piece
    get_user_info_from_userid
    if session[:chapman_code].present?
      @chapman_code = session[:chapman_code]
      @freecen2_piece = Freecen2Piece.find_by(_id: params[:piece_id])
      @year = @freecen2_piece.year
      @freecen2_civil_parishes = Freecen2CivilParish.where(freecen2_piece_id: params[:piece_id]).all.order_by(name: 1)
      @type = params[:type]
    else
      redirect_to manage_resources_path && return
    end
  end

  def show
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No civil parish identified') && return if params[:id].blank?

    get_user_info_from_userid
    @freecen2_civil_parish = Freecen2CivilParish.find_by(id: params[:id])
    @place = @freecen2_civil_parish.freecen2_place
    @piece = @freecen2_civil_parish.freecen2_piece
    @chapman_code = @freecen2_civil_parish.chapman_code
    @freecen2_piece = @freecen2_civil_parish.piece_name
    @type = params[:type]
  end

  def update
    # puts "\n\n*** update ***\n"
    redirect_back(fallback_location: manage_counties_path, notice: 'No information in the update') && return if params[:id].blank? || params[:freecen2_civil_parish].blank?

    @freecen2_civil_parish = Freecen2CivilParish.find_by(id: params[:id])
    redirect_back(fallback_location: manage_counties_path, notice: 'Civil Parish not found') && return if @freecen2_civil_parish.blank?

    chapman_code = @freecen2_civil_parish.chapman_code
    place = Freecen2Place.find_by(chapman_code: chapman_code, place_name: params[:freecen2_civil_parish][:name]) if chapman_code.present?
    params[:freecen2_civil_parish][:freecen2_place_id] = place.id if place.present?
    @type = params[:freecen2_civil_parish][:type]
    params[:freecen2_civil_parish].delete :type

    @freecen2_civil_parish.update_attributes(freecen2_civil_parish_params)
    if @freecen2_civil_parish.errors.any?
      flash[:notice] = "The update of the civil parish failed #{@freecen_csv_entry.errors.full_messages}."
      redirect_back(fallback_location: edit_freecen2_civil_parish_path(@freecen2_civil_parish, type: @type)) && return
    else
      flash[:notice] = 'Update was successful'
      redirect_to freecen2_civil_parish_path(@freecen2_civil_parish, type: @type)
    end
  end

  private

  def freecen2_civil_parish_params
    params.require(:freecen2_civil_parish).permit!
  end
end
