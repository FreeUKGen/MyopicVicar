class Freecen2CivilParishesController < ApplicationController
  require 'freecen_constants'

  def chapman_year_index
    get_user_info_from_userid
    @chapman_code = session[:chapman_code]
    session.delete(:freecen2_civil_parish)
    @year = params[:year]
    @freecen2_civil_parishes = Freecen2CivilParish.chapman_code(@chapman_code).year(@year).order_by(year: 1, name: 1)
    session[:type] = 'parish_year_index'
    @scotland = scotland_county?(@chapman_code)
  end

  def create
    # puts "\n\n*** create ***\n\n"
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No information in the creation') && return if params[:freecen2_civil_parish].blank?

    @new_civil_parish_params = Freecen2CivilParish.transform_civil_parish_params(params[:freecen2_civil_parish])

    @freecen2_civil_parish = Freecen2CivilParish.new(@new_civil_parish_params)
    get_user_info_from_userid
    @freecen2_civil_parish.reason_changed = "Created by #{session[:role]} (#{@user.userid})" if @freecen2_civil_parish.reason_changed.blank?

    @freecen2_civil_parish.save
    if @freecen2_civil_parish.errors.any?
      redirect_back(fallback_location: new_manage_resource_path, notice: "'There was an error while saving the new civil parish' #{@freecen2_civil_parish.errors.full_messages}") && return
    else
      @freecen2_civil_parish.reload
      @freecen2_piece = @freecen2_civil_parish.freecen2_piece
      civil_parish_names = @freecen2_piece.add_update_civil_parish_list
      @freecen2_piece.update(civil_parish_names: civil_parish_names)
      @freecen2_civil_parish.freecen2_hamlets << Freecen2CivilParish.add_hamlet(params) if params[:freecen2_civil_parish][:freecen2_hamlets_attributes].present?
      @freecen2_civil_parish.freecen2_townships << Freecen2CivilParish.add_township(params) if params[:freecen2_civil_parish][:freecen2_townships_attributes].present?
      @freecen2_civil_parish.freecen2_wards << Freecen2CivilParish.add_ward(params) if params[:freecen2_civil_parish][:freecen2_wards_attributes].present?
      @freecen2_civil_parish.save
      flash[:notice] = 'The civil parish was created'
      redirect_to freecen2_piece_path(@freecen2_piece)
    end
  end

  def csv_index
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No information') && return if params[:chapman_code].blank? || params[:year].blank?

    if params[:year] == 'all'
      freecen2_civil_parishes = Freecen2CivilParish.chapman_code(session[:chapman_code]).distinct(:name).sort_by(&:downcase)
    else
      freecen2_civil_parishes = Freecen2CivilParish.chapman_code(params[:chapman_code]).year(params[:year]).order_by(year: 1, name: 1).all
    end

    success, message, file_location, file_name = Freecen2CivilParish.create_csv_file(params[:chapman_code], params[:year], freecen2_civil_parishes)
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
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No Civil Parish identified') && return if params[:id].blank?

    @freecen2_civil_parish = Freecen2CivilParish.find_by(id: params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No Civil Parish found') && return if @freecen2_civil_parish.blank?
    @freecen2_piece = @freecen2_civil_parish.freecen2_piece

    success = @freecen2_civil_parish.destroy
    flash[:notice] = success ? 'Civil Parish deleted' : 'Civil Parish deletion failed'
    civil_parish_names = @freecen2_piece.add_update_civil_parish_list
    @freecen2_piece.update(civil_parish_names: civil_parish_names) unless civil_parish_names == @freecen2_piece.civil_parish_names

    redirect_to freecen2_civil_parishes_path
  end

  def district_place_name
    get_user_info_from_userid
    @chapman_code = session[:chapman_code]
    @freecen2_civil_parishes = Freecen2CivilParish.district_place_name(@chapman_code)
    session[:type] = 'parish_district_place_name'
    @scotland = scotland_county?(@chapman_code)
  end

  def edit
    redirect_back(fallback_location: new_manage_resource_path, notice:  'No civil parish identified') && return if params[:id].blank?

    get_user_info_from_userid
    @freecen2_civil_parish = Freecen2CivilParish.find_by(id: params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No civil parish found') && return if @freecen2_civil_parish.blank?

    @freecen2_place = @freecen2_civil_parish.freecen2_place
    @records = (@freecen2_place.present? && SearchRecord.where(freecen2_place_id: @freecen2_place.id).count.positive?) ? true : false
    @freecen2_place = @freecen2_place.present? ? @freecen2_place.place_name : ''
    @piece = @freecen2_civil_parish.freecen2_piece
    @chapman_code = @freecen2_civil_parish.chapman_code
    @freecen2_piece = @freecen2_civil_parish.piece_name
    @freecen2_civil_parishes = @freecen2_civil_parish.civil_parish_names
    @places = Freecen2Place.place_names_plus_alternates(@chapman_code)
    session[:freecen2_civil_parish] = @freecen2_civil_parish.name

    @freecen2_civil_parish.freecen2_hamlets.build
    @freecen2_civil_parish.freecen2_townships.build
    @freecen2_civil_parish.freecen2_wards.build
    @type = params[:type]
    @scotland = scotland_county?(@chapman_code)
  end

  def edit_name
    redirect_back(fallback_location: new_manage_resource_path, notice:  'No civil parish identified') && return if params[:id].blank?

    get_user_info_from_userid
    @freecen2_civil_parish = Freecen2CivilParish.find_by(id: params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No Civil Parish found') && return if @freecen2_civil_parish.blank?

    redirect_back(fallback_location: new_manage_resource_path, notice: 'Civil parish has csv files; so edit not permitted') && return if @freecen2_civil_parish.freecen2_piece.freecen_csv_files.present?

    @piece = @freecen2_civil_parish.freecen2_piece
    @type = session[:type]
    @chapman_code = session[:chapman_code]
    @scotland = scotland_county?(@chapman_code)
  end

  def full_index
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No Chapman code') && return if session[:chapman_code].blank?

    get_user_info_from_userid
    @census = Freecen::CENSUS_YEARS_ARRAY
    @chapman_code = session[:chapman_code]
    @freecen2_civil_parishes_distinct = Freecen2CivilParish.chapman_code(session[:chapman_code]).distinct(:name).sort_by(&:downcase)
    @freecen2_civil_parishes_distinct = Kaminari.paginate_array(@freecen2_civil_parishes_distinct).page(params[:page]).per(100)
    session[:current_page_civil_parish] = @freecen2_civil_parishes_distinct.current_page if @freecen2_civil_parishes_distinct.present?
    session[:type] = 'parish_index'
    @scotland = scotland_county?(@chapman_code)
  end

  def index
    get_user_info_from_userid
    if session[:chapman_code].present?
      @census = Freecen::CENSUS_YEARS_ARRAY
      @chapman_code = session[:chapman_code]
      session[:type] = 'parish'
      session.delete(:freecen2_civil_parish)
      @scotland = scotland_county?(@chapman_code)
    else
      flash[:notice] = 'No chapman_code'
      redirect_to new_manage_resource_path && return
    end
  end

  def index_for_piece
    get_user_info_from_userid

    if session[:chapman_code].blank?
      flash[:notice] = 'No chapman_code'
      return redirect_to new_manage_resource_path
    end

    @chapman_code = session[:chapman_code]
    @freecen2_piece = Freecen2Piece.find_by(_id: params[:piece_id])

    if @freecen2_piece.blank?
      flash[:notice] = 'Piece not found'
      return redirect_to new_manage_resource_path
    end
    @year = @freecen2_piece.year
    @freecen2_civil_parishes = Freecen2CivilParish.where(freecen2_piece_id: params[:piece_id]).all.order_by(name: 1)
    @type = params[:type]
    @scotland = scotland_county?(@chapman_code)
  end

  def missing_place
    get_user_info_from_userid
    @chapman_code = session[:chapman_code]
    @freecen2_civil_parishes = Freecen2CivilParish.missing_places(@chapman_code)
    session[:type] = 'missing_parish_index'
  end

  def new
    redirect_back(fallback_location: new_manage_resource_path, notice:  'No Piece identified') && return if params[:piece].blank?

    get_user_info_from_userid
    @freecen2_piece = Freecen2Piece.find_by(_id: params[:piece])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No Piece found') && return if @freecen2_piece.blank?

    @freecen2_place = @freecen2_piece.freecen2_place
    @freecen2_place_name = @freecen2_place.present? ? @freecen2_place.place_name : ''
    @chapman_code = @freecen2_piece.chapman_code
    @year = @freecen2_piece.year
    @freecen2_civil_parish = Freecen2CivilParish.new(freecen2_piece_id: @freecen2_piece.id, chapman_code: @chapman_code, year: @year, freecen2_place_id: @freecen2_place)
    @places = Freecen2Place.place_names_plus_alternates(@chapman_code)
    @freecen2_civil_parish.freecen2_hamlets.build
    @freecen2_civil_parish.freecen2_townships.build
    @freecen2_civil_parish.freecen2_wards.build
    session[:type] = session[:type] == 'district_year_index' ? 'district_year_index' : 'piece_year_index'
    @type = params[:type]
    @scotland = scotland_county?(@chapman_code)
  end

  def selection_by_name
    @chapman_code = session[:chapman_code]
    get_user_info_from_userid
    @freecen2_civil_parish = Freecen2CivilParish.new
    @options = {}
    Freecen2CivilParish.chapman_code(@chapman_code).order_by(name: 1, year: 1).each do |civil_parish|
      @options["#{civil_parish.name} (#{civil_parish.year}) (#{civil_parish.freecen2_piece.number})"] = civil_parish._id
    end
    @location = 'location.href= "/freecen2_civil_parishes/" + this.value'
    @prompt = 'Select Civil Parish)'
    session[:type] = 'parish_name'
    render '_form_for_selection'
  end

  def selection_by_year
    @chapman_code = session[:chapman_code]
    get_user_info_from_userid
    @freecen2_civil_parish = Freecen2CivilParish.new
    @options = Freecen::CENSUS_YEARS_ARRAY
    @location = 'location.href= "/freecen2_civil_parishes/chapman_year_index/?year=" + this.value'
    @prompt = 'Select Year'
    session[:type] = 'parish_year'
    render '_form_for_selection'
  end

  def show
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No civil parish identified') && return if params[:id].blank?

    get_user_info_from_userid
    @freecen2_civil_parish = Freecen2CivilParish.find_by(id: params[:id])
    flash[:notice] = 'No civil parish found' if @freecen2_civil_parish.blank?
    redirect_to new_manage_resource_path && return if @freecen2_civil_parish.blank?
    session[:freecen2_civil_parish] = @freecen2_civil_parish.name
    @year = @freecen2_civil_parish.year
    @name = @freecen2_civil_parish.name
    @place = @freecen2_civil_parish.freecen2_place
    @piece = @freecen2_civil_parish.freecen2_piece
    @chapman_code = @freecen2_civil_parish.chapman_code
    @freecen2_piece = @freecen2_civil_parish.piece_name
    @type = session[:type]
    @scotland = scotland_county?(@chapman_code)
  end

  def update
    # puts "\n\n*** update ***\n"
    redirect_back(fallback_location: manage_counties_path, notice: 'No information in the update') && return if params[:id].blank? || params[:freecen2_civil_parish].blank?

    @freecen2_civil_parish = Freecen2CivilParish.find_by(id: params[:id])
    redirect_back(fallback_location: manage_counties_path, notice: 'Civil Parish not found') && return if @freecen2_civil_parish.blank?

    if params[:commit] == 'Submit Name'
      redirect_back(fallback_location: manage_counties_path, notice: 'Civil Parish name must not be blank') && return if params[:freecen2_civil_parish][:name].blank?

      proceed = @freecen2_civil_parish.check_new_name(params[:freecen2_civil_parish][:name].strip)
      if proceed
        @freecen2_civil_parish.update_attributes(name: params[:freecen2_civil_parish][:name].strip)
        if @freecen2_civil_parish.errors.any?
          flash[:notice] = "The update of the civil parish name failed #{@freecen2_civil_parish.errors.full_messages}."
          redirect_back(fallback_location: edit_name_freecen2_civil_parish_path(@freecen2_piece, type: @type)) && return
        else
          @freecen2_piece = @freecen2_civil_parish.freecen2_piece
          civil_parish_names = @freecen2_piece.add_update_civil_parish_list
          @freecen2_piece.update(civil_parish_names: civil_parish_names) unless civil_parish_names == @freecen2_piece.civil_parish_names
          flash[:notice] = 'Update was successful'
          @type = session[:type]
          redirect_to freecen2_civil_parish_path(@freecen2_civil_parish, type: @type)
        end
      else
        flash[:notice] = 'The new name already exists please use the full edit to combine this civil parish with the existing civil parish of that name if that is what you want to achieve.'
        redirect_back(fallback_location: edit_name_freecen2_civil_parish_path(@freecen2_civil_parish, type: @type)) && return
      end
    else
      @old_freecen2_civil_parish_id = @freecen2_civil_parish.id
      @old_freecen2_civil_parish_name = @freecen2_civil_parish.name
      @old_place = @freecen2_civil_parish.freecen2_place_id
      @type = session[:type]
      params[:freecen2_civil_parish].delete :type
      merge_civil_parish = Freecen2CivilParish.find_by(name: params[:freecen2_civil_parish][:name], chapman_code: @freecen2_civil_parish.chapman_code, year: @freecen2_civil_parish.year, freecen2_piece_id: @freecen2_civil_parish.freecen2_piece_id)
      freecen2_place_id = Freecen2Place.place_id(@freecen2_civil_parish.chapman_code, params[:freecen2_civil_parish][:freecen2_place_id])
      if freecen2_place_id.present?
        params[:freecen2_civil_parish][:freecen2_place_id] = freecen2_place_id
      else
        flash[:notice] = "The update of the civil parish failed because we could not locate the place name."
        redirect_back(fallback_location: edit_freecen2_civil_parish_path(@freecen2_civil_parish, type: @type)) && return
      end


      @freecen2_civil_parish.update_attributes(freecen2_civil_parish_params)
      if @freecen2_civil_parish.reason_changed.blank?
        get_user_info_from_userid
        @freecen2_civil_parish.reason_changed = "Updated by #{session[:role]} (#{@user.userid})"
        @freecen2_civil_parish.save
      end
      if @freecen2_civil_parish.errors.any?
        flash[:notice] = "The update of the civil parish failed #{@freecen_csv_entry.errors.full_messages}."
        redirect_back(fallback_location: edit_freecen2_civil_parish_path(@freecen2_civil_parish, type: @type)) && return
      else
        flash[:notice] = 'Update was successful'
        get_user_info_from_userid
        @freecen2_civil_parish.update_tna_change_log(@user_userid)
        @freecen2_civil_parish.reload
        @freecen2_civil_parish.propagate(@old_freecen2_civil_parish_id, @old_freecen2_civil_parish_name, @old_place, merge_civil_parish)
        @freecen2_piece = @freecen2_civil_parish.freecen2_piece
        civil_parish_names = @freecen2_piece.add_update_civil_parish_list
        @freecen2_piece.update(civil_parish_names: civil_parish_names) unless civil_parish_names == @freecen2_piece.civil_parish_names
        parish = @freecen2_civil_parish.present? ? @freecen2_civil_parish.id : merge_civil_parish.id
        redirect_to freecen2_civil_parish_path(parish, type: @type)
      end
    end
  end

  private

  def freecen2_civil_parish_params
    params.require(:freecen2_civil_parish).permit!
  end
end
