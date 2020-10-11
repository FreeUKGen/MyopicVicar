class Freecen2CivilParishesController < ApplicationController
  require 'freecen_constants'

  def chapman_year_index
    get_user_info_from_userid
    @chapman_code = params[:chapman_code]
    session.delete(:freecen2_civil_parish)
    @year = params[:year]
    @freecen2_civil_parishes = Freecen2CivilParish.chapman_code(@chapman_code).year(@year).order_by(year: 1, name: 1)
    @type = 'parish_year_index'
  end

  def destroy
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No Civil Parish identified') && return if params[:id].blank?

    @freecen2_civil_parish = Freecen2CivilParish.find_by(id: params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No civil parish found') && return if @freecen2_civil_parish.blank?

    success = @freecen2_civil_parish.destroy
    flash[:notice] = success ? 'Civil Parish deleted' : 'Civil Parish deletion failed'
    redirect_to freecen2_civil_parishes_path
  end

  def district_place_name
    get_user_info_from_userid
    @chapman_code = session[:chapman_code]
    @freecen2_civil_parishes = Freecen2CivilParish.district_place_name(@chapman_code)
    @type = 'district_place_name'
  end

  def edit
    redirect_back(fallback_location: new_manage_resource_path, notice:  'No civil parish identified') && return if params[:id].blank?

    get_user_info_from_userid
    @freecen2_civil_parish = Freecen2CivilParish.find_by(id: params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No civil parish found') && return if @freecen2_civil_parish.blank?

    @freecen2_place = @freecen2_civil_parish.freecen2_place
    @freecen2_place = @freecen2_place.present? ? @freecen2_place.place_name : ''
    @piece = @freecen2_civil_parish.freecen2_piece
    @chapman_code = @freecen2_civil_parish.chapman_code
    @freecen2_piece = @freecen2_civil_parish.piece_name
    @freecen2_civil_parishes = @freecen2_civil_parish.civil_parish_names
    @places = @freecen2_civil_parish.civil_parish_place_names
    session[:freecen2_civil_parish] = @freecen2_civil_parish.name

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
      session[:current_page_civil_parish] = @freecen2_civil_parishes_distinct.current_page if @freecen2_civil_parishes_distinct.present?
      session.delete(:freecen2_civil_parish)
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

  def missing_place
    get_user_info_from_userid
    @chapman_code = session[:chapman_code]
    @freecen2_civil_parishes = Freecen2CivilParish.missing_places(@chapman_code)
    @type = 'missing_place_index'
  end

  def show
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No civil parish identified') && return if params[:id].blank?

    get_user_info_from_userid
    @freecen2_civil_parish = Freecen2CivilParish.find_by(id: params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No civil parish found') && return if @freecen2_civil_parish.blank?

    session[:freecen2_civil_parish] = @freecen2_civil_parish.name
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

    old_freecen2_place = @freecen2_civil_parish.freecen2_place_id
    old_civil_parish_name = @freecen2_civil_parish.name
    params[:freecen2_civil_parish][:freecen2_place_id] = @freecen2_civil_parish.civil_parish_place_id(params[:freecen2_civil_parish][:freecen2_place_id])
    @type = params[:freecen2_civil_parish][:type]
    params[:freecen2_civil_parish].delete :type

    @freecen2_civil_parish.update_attributes(freecen2_civil_parish_params)
    if @freecen2_civil_parish.errors.any?
      flash[:notice] = "The update of the civil parish failed #{@freecen_csv_entry.errors.full_messages}."
      redirect_back(fallback_location: edit_freecen2_civil_parish_path(@freecen2_civil_parish, type: @type)) && return
    else
      flash[:notice] = 'Update was successful'
      get_user_info_from_userid
      @freecen2_civil_parish.update_tna_change_log(@user_userid)
      @freecen2_civil_parish.reload
      @freecen2_civil_parish.propagate_freecen2_place(old_freecen2_place, old_civil_parish_name)
      redirect_to freecen2_civil_parish_path(@freecen2_civil_parish, type: @type)
    end
  end

  private

  def freecen2_civil_parish_params
    params.require(:freecen2_civil_parish).permit!
  end
end
