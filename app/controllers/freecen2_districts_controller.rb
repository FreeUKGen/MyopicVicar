class Freecen2DistrictsController < ApplicationController
  require 'freecen_constants'

  def chapman_year_index
    get_user_info_from_userid
    @chapman_code = params[:chapman_code]
    @year = params[:year]
    session.delete(:freecen2_piece)
    session.delete(:freecen2_civil_parish)
    session.delete(:current_page_piece)
    session.delete(:current_page_civil_parish)
    @freecen2_districts = Freecen2District.chapman_code(@chapman_code).year(@year).order_by(year: 1, name: 1).all
    @type = 'district_year_index'
  end

  def edit
    redirect_back(fallback_location: new_manage_resource_path, notice:  'No civil parish identified') && return if params[:id].blank?

    get_user_info_from_userid
    @freecen2_district = Freecen2District.find_by(id: params[:id])
    session[:freecen2_district] = @freecen2_district.name
    @freecen2_place = @freecen2_district.freecen2_place
    @freecen2_place = @freecen2_place.present? ? @freecen2_place.place_name : ''
    @districts = @freecen2_district.district_names
    @places = @freecen2_district.district_place_names
    @type = params[:type]
  end

  def index
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No Chapman code') && return if session[:chapman_code].blank?

    get_user_info_from_userid
    @census = Freecen::CENSUS_YEARS_ARRAY
    @chapman_code = session[:chapman_code]
    @freecen2_districts_distinct = Freecen2District.chapman_code(session[:chapman_code]).distinct(:name).sort_by(&:downcase)
    @freecen2_districts_distinct = Kaminari.paginate_array(@freecen2_districts_distinct).page(params[:page]).per(50)
    session[:current_page_district] = @freecen2_districts_distinct.current_page if @freecen2_districts_distinct.present?
    session.delete(:freecen2_district)
    @type = 'district_index'
  end

  def locate
    @type = params[:type]
    @freecen2_district = Freecen2District.find_by(chapman_code: params[:chapman_code], year: params[:year], name: params[:name])
    redirect_to freecen2_district_path(@freecen2_district.id, type: @type)
  end

  def missing_place
    get_user_info_from_userid
    @chapman_code = session[:chapman_code]
    @freecen2_districts = Freecen2District.missing_places(@chapman_code)
    @type = 'missing_place_index'
  end

  def show
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No District identified') && return if params[:id].blank?
    @type = params[:type]
    get_user_info_from_userid
    @freecen2_district = Freecen2District.find_by(id: params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No District found') && return if @freecen2_district.blank?

    @freecen2_pieces_name = @freecen2_district.freecen2_pieces_name
    @place = @freecen2_district.freecen2_place
    @chapman_code = session[:chapman_code]
    session[:freecen2_district] = @freecen2_district.name
    @type = params[:type]
  end

  def update
    # puts "\n\n*** update ***\n"
    redirect_back(fallback_location: manage_counties_path, notice: 'No information in the update') && return if params[:id].blank? || params[:freecen2_district].blank?

    @freecen2_district = Freecen2District.find_by(id: params[:id])
    redirect_back(fallback_location: manage_counties_path, notice: 'District not found') && return if @freecen2_district.blank?

    old_freecen2_place = @freecen2_district.freecen2_place_id
    old_district_name = @freecen2_district.name
    params[:freecen2_district][:freecen2_place_id] = @freecen2_district.district_place_id(params[:freecen2_district][:freecen2_place_id])
    @type = params[:freecen2_district][:type]
    params[:freecen2_district].delete :type

    @freecen2_district.update_attributes(freecen2_district_params)

    if @freecen2_district.errors.any?
      flash[:notice] = "The update of the civil parish failed #{@freecen_csv_entry.errors.full_messages}."
      redirect_back(fallback_location: edit_freecen2_district_path(@freecen2_district, type: @type)) && return
    else
      flash[:notice] = 'Update was successful'
      get_user_info_from_userid
      @freecen2_district.update_tna_change_log(@user_userid)
      @freecen2_district.reload
      @freecen2_district.propagate_freecen2_place(old_freecen2_place, old_district_name)
      redirect_to freecen2_district_path(@freecen2_district, type: @type)
    end
  end
  private

  def freecen2_district_params
    params.require(:freecen2_district).permit!
  end

end
