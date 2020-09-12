class Freecen2DistrictsController < ApplicationController
  require 'freecen_constants'

  def chapman_year_index
    get_user_info_from_userid
    @chapman_code = params[:chapman_code]
    @year = params[:year]
    @freecen2_districts = Freecen2District.chapman_code(@chapman_code).year(@year).order_by(year: 1, name: 1).all
    @type = 'district_year_index'
  end

  def edit
    redirect_back(fallback_location: new_manage_resource_path, notice:  'No civil parish identified') && return if params[:id].blank?

    get_user_info_from_userid
    @freecen2_district = Freecen2District.find_by(id: params[:id])
    @freecen2_place = @freecen2_district.freecen2_place

    places = Freecen2Place.chapman_code(@freecen2_district.chapman_code).all.order_by(place_name: 1)
    @places = []
    places.each do |place|
      @places << place.place_name
    end
    @type = params[:type]
  end

  def index
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No Chapman code') && return if session[:chapman_code].blank?

    get_user_info_from_userid
    @census = Freecen::CENSUS_YEARS_ARRAY
    @chapman_code = session[:chapman_code]
    @freecen2_districts_distinct = Freecen2District.chapman_code(session[:chapman_code]).distinct(:name).sort_by(&:downcase)
    @freecen2_districts_distinct = Kaminari.paginate_array(@freecen2_districts_distinct).page(params[:page]).per(50)
    @type = 'district_index'
  end

  def locate
    @type = params[:type]
    @freecen2_district = Freecen2District.find_by(chapman_code: params[:chapman_code], year: params[:year], name: params[:name])
    redirect_to freecen2_district_path(@freecen2_district.id, type: @type)
  end

  def show
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No District identified') && return if params[:id].blank?
    @type = params[:type]
    get_user_info_from_userid
    @freecen2_district = Freecen2District.find_by(id: params[:id])
    @freecen2_pieces = Freecen2Piece.where(freecen2_district_id: @freecen2_district.id).all.order_by(name: 1)
    @freecen2_pieces_name = []
    @freecen2_pieces.each do |piece|
      @freecen2_pieces_name << piece.name unless @freecen2_pieces_name.include?(piece.name)
    end
    @place = @freecen2_district.freecen2_place
    @chapman_code = session[:chapman_code]
    @type = params[:type]
  end

  def update
    # puts "\n\n*** update ***\n"
    redirect_back(fallback_location: manage_counties_path, notice: 'No information in the update') && return if params[:id].blank? || params[:freecen2_district].blank?

    @freecen2_district = Freecen2District.find_by(id: params[:id])
    redirect_back(fallback_location: manage_counties_path, notice: 'Civil Parish not found') && return if @freecen2_district.blank?

    chapman_code = @freecen2_district.chapman_code
    place = Freecen2Place.find_by(chapman_code: chapman_code, place_name: params[:freecen2_district][:name]) if chapman_code.present?
    params[:freecen2_district][:freecen2_place_id] = place.id if place.present?
    @type = params[:freecen2_district][:type]
    params[:freecen2_district].delete :type

    @freecen2_district.update_attributes(freecen2_district_params)

    if @freecen2_district.errors.any?
      flash[:notice] = "The update of the civil parish failed #{@freecen_csv_entry.errors.full_messages}."
      redirect_back(fallback_location: edit_freecen2_district_path(@freecen2_district, type: @type)) && return
    else
      flash[:notice] = 'Update was successful'
      get_user_info_from_userid
      p  @freecen2_district.previous_changes
      @freecen2_district.update_freecen2_place
      @freecen2_district.update_tna_change_log(@user_userid)
      redirect_to freecen2_district_path(@freecen2_district, type: @type)
    end
  end
  private

  def freecen2_district_params
    params.require(:freecen2_district).permit!
  end

end
