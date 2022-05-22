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

  def create
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No information in the creation') && return if params[:freecen2_district].blank?

    params[:freecen2_district][:name] = params[:freecen2_district][:name].strip if params[:freecen2_district][:name].present?
    params[:freecen2_district][:freecen2_place_id] = Freecen2Place.place_id(params[:freecen2_district][:chapman_code], params[:freecen2_district][:freecen2_place_id])
    @freecen2_district = Freecen2District.new(freecen2_district_params)
    @freecen2_district.save
    if @freecen2_district.errors.any?
      redirect_back(fallback_location: new_manage_resource_path, notice: "'There was an error while saving the new piece' #{@freecen2_district.errors.full_messages}") && return
    else
      @freecen2_district.reload
      flash[:notice] = 'The district was created'
      redirect_to freecen2_district_path(@freecen2_district)
    end
  end

  def csv_index
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No information') && return if params[:chapman_code].blank? || params[:year].blank?

    if params[:year] == 'all'
      freecen2_districts = Freecen2District.chapman_code(session[:chapman_code]).distinct(:name).sort_by(&:downcase)
    else
      freecen2_districts = Freecen2District.chapman_code(params[:chapman_code]).year(params[:year]).order_by(year: 1, name: 1).all
    end

    success, message, file_location, file_name = Freecen2District.create_csv_file(params[:chapman_code], params[:year], freecen2_districts)
    if success
      if File.file?(file_location)
        send_file(file_location, filename: file_name, x_sendfile: true) && return
        flash[:notice] = 'Downloaded'
      end
    else
      flash[:notice] = "There was a problem saving the file prior to download. Please send this message #{message} to your coordinator"
    end
    redirect_back(fallback_location: new_manage_resource_path)
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
    @records = (@freecen2_place.present? && SearchRecord.where(freecen2_place_id: @freecen2_place.id).count.positive?) ? true : false
    @freecen2_place = @freecen2_place.present? ? @freecen2_place.place_name : ''
    @districts = @freecen2_district.district_names
    @places = @freecen2_district.district_place_names
    @type = session[:type]
    @chapman_code = session[:chapman_code]
    @scotland = scotland_county?(@chapman_code)
  end

  def edit_name
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No district identified') && return if params[:id].blank?

    get_user_info_from_userid
    @freecen2_district = Freecen2District.find_by(id: params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No district found') && return if @freecen2_district.blank?

    redirect_back(fallback_location: new_manage_resource_path, notice: 'District has files so edit not permitted') && return if @freecen2_district.freecen_csv_files.present?

    @type = session[:type]
    @chapman_code = session[:chapman_code]
    @scotland = scotland_county?(@chapman_code)
  end

  def force
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No district identified') && return if params[:id].blank?

    @freecen2_district = Freecen2District.find_by(id: params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No district found') && return if @freecen2_district.blank?

    logger.warn("FREECEN:CSV_PROCESSING: Starting forced deletion rake task for #{@freecen2_district.name}")
    pid1 = spawn("rake foo:delete_incorrect_tna_district[#{params[:id]}]")
    flash[:notice] = "The civil parishes, pieces and district for #{@freecen2_district.name} are being deleted. You will receive an email when the task has been completed."
    logger.warn("FREECEN:CSV_PROCESSING: rake task for #{pid1}")

    redirect_to freecen2_districts_path
  end

  def index
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No Chapman code') && return if session[:chapman_code].blank?

    get_user_info_from_userid
    @chapman_code = session[:chapman_code]
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
    @freecen2_district = Freecen2District.find_by(chapman_code: params[:chapman_code], year: params[:year], standard_name: Freecen2Place.standard_place(params[:name]))
    redirect_to freecen2_district_path(@freecen2_district.id, type: @type)
  end

  def missing_place
    get_user_info_from_userid
    @chapman_code = session[:chapman_code]
    @freecen2_districts = Freecen2District.missing_places(@chapman_code)
    session[:type] = 'missing_district_place_index'
  end

  def new
    @year = params[:year]
    @chapman_code = params[:chapman_code]
    redirect_back(fallback_location: new_manage_resource_path, notice:  'No Chapman code or year identified') && return if @chapman_code.blank? || @year.blank?

    get_user_info_from_userid
    @places = Freecen2Place.place_names_plus_alternates(@chapman_code)
    @freecen2_district = Freecen2District.new(chapman_code: params[:chapman_code], year: params[:year])
    session[:type] = 'district_year_index'
    @type = session[:type]
    @scotland = scotland_county?(@chapman_code)
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
    flash[:notice] = 'No District found' if @freecen2_district.blank?
    redirect_to new_manage_resource_path && return if @freecen2_district.blank?

    @freecen2_pieces_name = @freecen2_district.freecen2_pieces_name
    @place = @freecen2_district.freecen2_place
    @chapman_code = session[:chapman_code]
    session[:freecen2_district] = @freecen2_district.name
    @type = session[:type]
    @scotland = scotland_county?(@chapman_code)
  end

  def update
    # puts "\n\n*** update ***\n"
    redirect_back(fallback_location: manage_counties_path, notice: 'No information in the update') && return if params[:id].blank? ||
      params[:freecen2_district].blank?

    @freecen2_district = Freecen2District.find_by(id: params[:id])
    redirect_back(fallback_location: manage_counties_path, notice: 'District not found') && return if @freecen2_district.blank?

    if params[:commit] == 'Submit Name'
      redirect_back(fallback_location: manage_counties_path, notice: 'District name must not be blank') && return if params[:freecen2_district][:name].blank?

      proceed = @freecen2_district.check_new_name(params[:freecen2_district][:name].strip)
      if proceed
        @freecen2_district.update_attributes(name: params[:freecen2_district][:name].strip)
        if @freecen2_district.errors.any?
          flash[:notice] = "The update of the district name failed #{@freecen2_district.errors.full_messages}."
          redirect_back(fallback_location: edit_name_freecen2_district_path(@freecen2_district, type: @type)) && return
        else
          flash[:notice] = 'Update was successful'
          @type = session[:type]
          redirect_to freecen2_district_path(@freecen2_district, type: @type)
        end
      else
        flash[:notice] = 'The new name already exists please use the full edit to combine this district with the existing district of that name if that is what you want to achieve.'
        redirect_back(fallback_location: edit_name_freecen2_district_path(@freecen2_district, type: @type)) && return
      end
    else
      @old_district = @freecen2_district
      @old_freecen2_district_id = @freecen2_district.id
      @old_freecen2_district_name = @freecen2_district.name
      @old_place = @freecen2_district.freecen2_place_id
      merge_district = Freecen2District.find_by(name: params[:freecen2_district][:name], chapman_code: @freecen2_district.chapman_code, year: @freecen2_district.year)

      params[:freecen2_district][:freecen2_place_id] = @freecen2_district.district_place_id(params[:freecen2_district][:freecen2_place_id])

      params[:freecen2_district].delete :type

      @freecen2_district.update_attributes(freecen2_district_params)

      if @freecen2_district.errors.any?
        flash[:notice] = "The update of the district failed #{@freecen2_district.errors.full_messages}."
        redirect_back(fallback_location: edit_freecen2_district_path(@freecen2_district, type: @type)) && return
      else
        flash[:notice] = 'Update was successful'
        get_user_info_from_userid
        @freecen2_district.update_tna_change_log(@user_userid)
        @freecen2_district.reload
        @freecen2_district.propagate(@old_freecen2_district_id, @old_freecen2_district_name, @old_place, merge_district)
        district = merge_district.present? ? merge_district.id : @freecen2_district.id
        redirect_to freecen2_district_path(district, type: @type)
      end
    end

  end

  private

  def freecen2_district_params
    params.require(:freecen2_district).permit!
  end
end
