class Freecen2PiecesController < ApplicationController
  require 'freecen_constants'

  def chapman_year_index
    get_user_info_from_userid
    @chapman_code = session[:chapman_code]
    @year = params[:year]
    @freecen2_pieces = Freecen2Piece.chapman_code(@chapman_code).year(@year).order_by(year: 1, name: 1, number: 1).all
    session.delete(:freecen2_civil_parish)
    session.delete(:current_page_civil_parish)
    session[:type] = 'piece_year_index'
  end

  def create
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No information in the creation') && return if params[:freecen2_piece].blank?

    @new_freecen2_piece_params = Freecen2Piece.transform_piece_params(params[:freecen2_piece])
    @freecen2_piece = Freecen2Piece.new(@new_freecen2_piece_params)
    @freecen2_piece.save
    if @freecen2_piece.errors.any?
      redirect_back(fallback_location: new_manage_resource_path, notice: "'There was an error while saving the new piece' #{@freecen2_piece.errors.full_messages}") && return
    else
      @freecen2_piece.reload
      @freecen2_district = @freecen2_piece.freecen2_district
      civil_parish_names = @freecen2_piece.add_update_civil_parish_list
      @freecen2_piece.update(civil_parish_names: civil_parish_names)
      flash[:notice] = 'The piece was created'
      redirect_to freecen2_piece_path(@freecen2_piece)
    end
  end

  def csv_index
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No information') && return if params[:chapman_code].blank? || params[:year].blank?

    if params[:year] == 'all'
      freecen2_pieces = Freecen2Piece.chapman_code(session[:chapman_code]).distinct(:name).sort_by(&:downcase)
    else
      freecen2_pieces = Freecen2Piece.chapman_code(params[:chapman_code]).year(params[:year]).order_by(year: 1, name: 1).all
    end

    success, message, file_location, file_name = Freecen2Piece.create_csv_file(params[:chapman_code], params[:year], freecen2_pieces)
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
    @places = Freecen2Place.place_names_plus_alternates(@chapman_code)
    @type = session[:type]
  end

  def edit_name
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No piece identified') && return if params[:id].blank?

    get_user_info_from_userid
    @freecen2_piece = Freecen2Piece.where('_id' => params[:id]).first
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No piece found') && return if @freecen2_piece.blank?

    redirect_back(fallback_location: new_manage_resource_path, notice: 'Piece has csv files; so edit not permitted') && return if @freecen2_piece.freecen_csv_files.present?

    @type = session[:type]
    @chapman_code = session[:chapman_code]
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
      @freecen2_pieces = Freecen2Piece.where(freecen2_district_id: @freecen2_district.id).all.order_by(name: 1, number: 1)
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

  def new
    redirect_back(fallback_location: new_manage_resource_path, notice:  'No district identified') && return if params[:district].blank?

    get_user_info_from_userid
    @freecen2_district = Freecen2District.find_by(_id: params[:district])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No district found') && return if @freecen2_district.blank?

    @freecen2_place = @freecen2_district.freecen2_place
    @freecen2_place_name = @freecen2_place.present? ? @freecen2_place.place_name : ''
    @chapman_code = @freecen2_district.chapman_code
    @year = @freecen2_district.year
    @places = Freecen2Place.place_names_plus_alternates(@chapman_code)
    @freecen2_piece = Freecen2Piece.new(freecen2_district_id: @freecen2_district.id, chapman_code: @chapman_code, year: @year, freecen2_place_id: @freecen2_place)
    session[:type] = 'district_year_index'
    @type = params[:type]
  end

  def refresh_civil_parish_list
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No piece identified') && return if params[:id].blank?

    get_user_info_from_userid
    @freecen2_piece = Freecen2Piece.find_by(id: params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No piece found') && return if @freecen2_piece.blank?

    civil_parish_names = @freecen2_piece.add_update_civil_parish_list
    @freecen2_piece.update(civil_parish_names: civil_parish_names) unless civil_parish_names == @freecen2_piece.civil_parish_names
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Civil Parish List Updated if necessary')
  end

  def selection_by_number
    @chapman_code = session[:chapman_code]
    get_user_info_from_userid
    @freecen2_piece = Freecen2Piece.new
    @options = {}
    Freecen2Piece.chapman_code(@chapman_code).order_by(number: 1, year: 1).each do |piece|
      @options["#{piece.number} (#{piece.year}) (#{piece.name})"] = piece._id
    end
    @location = 'location.href= "/freecen2_pieces/" + this.value'
    @prompt = 'Select Sub district (Piece) by number'
    session[:type] = 'piece_name'
    render '_form_for_selection'
  end

  def selection_by_name
    @chapman_code = session[:chapman_code]
    get_user_info_from_userid
    @freecen2_piece = Freecen2Piece.new
    @options = {}
    Freecen2Piece.chapman_code(@chapman_code).order_by(name: 1, year: 1).each do |piece|
      @options["#{piece.name} (#{piece.year}) (#{piece.number})"] = piece._id
    end
    @location = 'location.href= "/freecen2_pieces/" + this.value'
    @prompt = 'Select Sub district (Piece) by name'
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
    if @freecen2_piece.blank?
      flash[:notice] = 'No piece found'
      return redirect_to new_manage_resource_path
    end

    @place = @freecen2_piece.freecen2_place
    @chapman_code = session[:chapman_code]
    @type = session[:type]
    session[:freecen2_piece] = @freecen2_piece.name
  end

  def update
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No information in the update') && return if params[:id].blank? || params[:freecen2_piece].blank?

    @freecen2_piece = Freecen2Piece.find_by(_id: params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Piece not found') && return if @freecen2_piece.blank?
    get_user_info_from_userid
    if params[:commit] == 'Submit Name'
      redirect_back(fallback_location: manage_counties_path, notice: 'Piece name must not be blank') && return if params[:freecen2_piece][:name].blank?

      proceed = @freecen2_piece.check_new_name(params[:freecen2_piece][:name].strip, @user)
      if proceed
        @freecen2_piece.update_attributes(name: params[:freecen2_piece][:name].strip)
        if @freecen2_piece.errors.any?
          flash[:notice] = "The update of the piece name failed #{@freecen2_piece.errors.full_messages}."
          redirect_back(fallback_location: edit_name_freecen2_piece_path(@freecen2_piece, type: @type)) && return
        else
          flash[:notice] = 'Update was successful'
          @type = session[:type]
          redirect_to freecen2_piece_path(@freecen2_piece, type: @type)
        end
      else
        flash[:notice] = 'The new name already exists please use the full edit to combine this piece with the existing piece of that name if that is what you want to achieve.'
        redirect_back(fallback_location: edit_name_freecen2_piece_path(@freecen2_piece, type: @type)) && return
      end
    else
      @old_freecen2_piece_id = @freecen2_piece.id
      @old_freecen2_piece_name = @freecen2_piece.name
      @old_place = @freecen2_piece.freecen2_place_id
      merge_piece = Freecen2Piece.find_by(name: params[:freecen2_piece][:name], chapman_code: @freecen2_piece.chapman_code, year: @freecen2_piece.year, freecen2_district_id: @freecen2_piece.freecen2_district_id)
      params[:freecen2_piece][:freecen2_place_id] = Freecen2Place.place_id(@freecen2_piece.chapman_code, params[:freecen2_piece][:freecen2_place_id])
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
        @freecen2_piece.propagate(@old_freecen2_piece_id, @old_freecen2_piece_name, @old_place, merge_piece)
        piece = @freecen2_piece.present? ? @freecen2_piece.id : merge_piece.id
        redirect_to freecen2_piece_path(piece, type: @type)
      end
    end
  end

  private

  def freecen2_piece_params
    params.require(:freecen2_piece).permit!
  end
end
