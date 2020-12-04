class Freecen2DistrictsController < ApplicationController
  require 'freecen_constants'

  def chapman_year_index
    get_user_info_from_userid
    @chapman_code = session[:chapman_code]
    @year = params[:year]
    session.delete(:freecen2_piece)
    session.delete(:freecen2_civil_parish)
    session.delete(:current_page_piece)
    session.delete(:current_page_civil_parish)
    @freecen2_districts = Freecen2District.chapman_code(@chapman_code).year(@year).order_by(year: 1, name: 1).all
    session[:type] = 'district_year_index'
  end

  def copy
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No district identified') && return if params[:id].blank?

    @freecen2_district = Freecen2District.find_by(id: params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No district found') && return if @freecen2_district.blank?

    get_user_info_from_userid
    @options = @freecen2_district.get_counties
    session[:freecen2_district] = params[:id]
    @location = 'location.href= "/freecen2_districts/complete_copy?chapman_code=" + this.value'
    @prompt = 'Select Chapman Code'
    render '_form_for_selection'
  end

  def complete_copy
    @chapman_code = params[:chapman_code]
    @freecen2_district = Freecen2District.find_by(id: session[:freecen2_district])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No district found') && return if @freecen2_district.blank?

    success, freecen2_district = @freecen2_district.copy_to_another_county(@chapman_code)
    session.delete(:freecen2_district)
    if success
      session[:chapman_code] = @chapman_code
      flash[:notice] = 'Success'
      redirect_to freecen2_district_path(freecen2_district, type: 'district_index')
    else
      flash[:notice] = 'Failure'
      redirect_to freecen2_district_path(@freecen2_district, type: 'district_index')
    end
  end

  def destroy
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No district identified') && return if params[:id].blank?

    @freecen2_district = Freecen2District.find_by(id: params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No district found') && return if @freecen2_district.blank?

    success = @freecen2_district.destroy
    flash[:notice] = success ? 'District deleted' : 'District deletion failed'
    redirect_to freecen2_districts_path
  end

  def edit
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No district identified') && return if params[:id].blank?

    get_user_info_from_userid
    @freecen2_district = Freecen2District.find_by(id: params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No district found') && return if @freecen2_district.blank?

    session[:freecen2_district] = @freecen2_district.name
    @freecen2_place = @freecen2_district.freecen2_place
    @freecen2_place = @freecen2_place.present? ? @freecen2_place.place_name : ''
    @districts = @freecen2_district.district_names
    @places = @freecen2_district.district_place_names
    @type = session[:type]
    @chapman_code = session[:chapman_code]
  end

  def index
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No Chapman code') && return if session[:chapman_code].blank?

    get_user_info_from_userid
    @census = Freecen::CENSUS_YEARS_ARRAY
    @chapman_code = session[:chapman_code]
    @freecen2_districts_distinct = Freecen2District.chapman_code(session[:chapman_code]).distinct(:name).sort_by(&:downcase)
    @freecen2_districts_distinct = Kaminari.paginate_array(@freecen2_districts_distinct).page(params[:page]).per(100)
    session[:current_page_district] = @freecen2_districts_distinct.current_page if @freecen2_districts_distinct.present?
    session.delete(:freecen2_district)
    session[:type] = 'district'
  end

  def full_index
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No Chapman code') && return if session[:chapman_code].blank?

    get_user_info_from_userid
    @census = Freecen::CENSUS_YEARS_ARRAY
    @chapman_code = session[:chapman_code]
    @freecen2_districts_distinct = Freecen2District.chapman_code(session[:chapman_code]).distinct(:name).sort_by(&:downcase)
    @freecen2_districts_distinct = Kaminari.paginate_array(@freecen2_districts_distinct).page(params[:page]).per(100)
    session[:current_page_district] = @freecen2_districts_distinct.current_page if @freecen2_districts_distinct.present?
    session.delete(:freecen2_district)
    session[:type] = 'district_index'
  end

  def locate
    @type = session[:type]
    @freecen2_district = Freecen2District.find_by(chapman_code: params[:chapman_code], year: params[:year], name: params[:name])
    redirect_to freecen2_district_path(@freecen2_district.id, type: @type)
  end

  def missing_place
    get_user_info_from_userid
    @chapman_code = session[:chapman_code]
    @freecen2_districts = Freecen2District.missing_places(@chapman_code)
    session[:type] = 'missing_district_place_index'
  end

  def selection_by_name
    @chapman_code = session[:chapman_code]
    get_user_info_from_userid
    @freecen2_district = Freecen2District.new
    freecen2_districts = {}
    Freecen2District.chapman_code(@chapman_code).order_by(name: 1, year: 1).each do |district|
      freecen2_districts["#{district.name} (#{district.year})"] = district._id
    end
    @options = freecen2_districts
    @location = 'location.href= "/freecen2_districts/" + this.value'
    @prompt = 'Select the specific District'
    session[:type] = 'district_name'
    render '_form_for_selection'
  end

  def selection_by_year
    @chapman_code = session[:chapman_code]
    get_user_info_from_userid
    @freecen2_district = Freecen2District.new
    @options = Freecen::CENSUS_YEARS_ARRAY

    @location = 'location.href= "/freecen2_districts/chapman_year_index/?year=" + this.value'
    @prompt = 'Select the Year'
    session[:type] = 'district_year'
    render '_form_for_selection'
  end

  def show
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No District identified') && return if params[:id].blank?
    @type = session[:type]
    get_user_info_from_userid
    @freecen2_district = Freecen2District.find_by(id: params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No District found') && return if @freecen2_district.blank?

    @freecen2_pieces_name = @freecen2_district.freecen2_pieces_name
    @place = @freecen2_district.freecen2_place
    @chapman_code = session[:chapman_code]
    session[:freecen2_district] = @freecen2_district.name
    @type = session[:type]
  end

  def update
    # puts "\n\n*** update ***\n"
    redirect_back(fallback_location: manage_counties_path, notice: 'No information in the update') && return if params[:id].blank? ||
      params[:freecen2_district].blank?

    @freecen2_district = Freecen2District.find_by(id: params[:id])
    redirect_back(fallback_location: manage_counties_path, notice: 'District not found') && return if @freecen2_district.blank?

    old_freecen2_place = @freecen2_district.freecen2_place_id
    old_district_name = @freecen2_district.name
    params[:freecen2_district][:freecen2_place_id] = @freecen2_district.district_place_id(params[:freecen2_district][:freecen2_place_id])
    @type = session[:type]
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
