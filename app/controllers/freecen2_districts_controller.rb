class Freecen2DistrictsController < ApplicationController
  require 'freecen_constants'

  def chapman_year_index
    get_user_info_from_userid
    @chapman_code = params[:chapman_code]
    @year = params[:year]
    @freecen2_districts = Freecen2District.chapman_code(@chapman_code).year(@year).order_by(year: 1, name: 1).all
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
  end

  def index
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No Chapman code') && return if session[:chapman_code].blank?

    get_user_info_from_userid
    @census = Freecen::CENSUS_YEARS_ARRAY
    @chapman_code = session[:chapman_code]
    @freecen2_districts_distinct = Freecen2District.chapman_code(session[:chapman_code]).distinct(:name).sort_by(&:downcase)
    @freecen2_districts_distinct = Kaminari.paginate_array(@freecen2_districts_distinct).page(params[:page]).per(50)
  end

  def locate
    @freecen2_district = Freecen2District.find_by(chapman_code: params[:chapman_code], year: params[:year], name: params[:name])
    redirect_to freecen2_district_path(@freecen2_district.id, type: 'index')
  end

  def show
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No District identified') && return if params[:id].blank?
    @type = params[:type]
    get_user_info_from_userid
    @freecen2_district = Freecen2District.find_by(id: params[:id])
    @place = @freecen2_district.freecen2_place
    @chapman_code = session[:chapman_code]
  end

  def update
    # puts "\n\n*** update ***\n"
    redirect_back(fallback_location: manage_counties_path, notice: 'No information in the update') && return if params[:id].blank? || params[:freecen2_district].blank?

    @freecen2_district = Freecen2District.find_by(id: params[:id])
    redirect_back(fallback_location: manage_counties_path, notice: 'Civil Parish not found') && return if @freecen2_district.blank?

    chapman_code = @freecen2_district.chapman_code
    place = Freecen2Place.find_by(chapman_code: chapman_code, place_name: params[:freecen2_district][:name]) if chapman_code.present?
    params[:freecen2_district][:freecen2_place_id] = place.id if place.present?
    @freecen2_district.update_attributes(freecen2_district_params)
    if @freecen2_district.errors.any?
      flash[:notice] = "The update of the civil parish failed #{@freecen_csv_entry.errors.full_messages}."
      redirect_back(fallback_location: edit_freecen2_district_path(@freecen2_district)) && return
    else
      flash[:notice] = 'Update was successful'
      redirect_to freecen2_district_path(@freecen2_district)
    end
  end
  private

  def freecen2_district_params
    params.require(:freecen2_district).permit!
  end

end
