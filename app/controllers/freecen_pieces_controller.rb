class FreecenPiecesController < ApplicationController
  require 'freecen_constants'
  def create
    # puts "\n\n*** create ***\n\n"
    redirect_to(freecen_pieces_path, notice: 'No information in the creation') && return if params[:freecen_piece].blank?

    @new_piece_params = FreecenPiece.transform_piece_params(params[:freecen_piece])
    @piece_params_errors = FreecenPiece.check_piece_params(@new_piece_params, controller_name)
    redirect_to(piece_new_freecen_piece_path(chapman_code:@new_piece_params[:chapman_code]), notice: "Could not create the new piece #{@piece_params_errors}") &&
      return if @piece_params_errors.present? && @piece_params_errors.any?

    @freecen_piece = FreecenPiece.new(@new_piece_params)
    success, place_params = FreecenPiece.set_piece_place(@freecen_piece)
    @new_piece_params = @new_piece_params.merge(place_params) if success
    success = @freecen_piece.update(@new_piece_params) if success
    @freecen_piece.save if success
    if @freecen_piece.errors.any?
      redirect_to(piece_new_freecen_piece_path(chapman_code: @freecen_piece[:chapman_code]),
                  notice: "'There was an error while saving the new piece' #{@freecen_piece.errors.full_messages}") && return
    else
      flash[:notice] = 'Piece creation was successful'
      # clear cached database coverage so it picks up the change for display
      Rails.cache.delete('freecen_coverage_index')
      # redirect to the right page
      if session[:manage_user_origin] == 'manage county'
        redirect_to freecen_piece_path(@freecen_piece.id)
      else
        next_page = freecen_coverage_path + "/#{@freecen_piece.chapman_code}##{@freecen_piece.year}"
        redirect_to next_page
      end
    end
  end

  def chapman_year_index
    get_user_info_from_userid
    @chapman_code = params[:chapman_code]
    @year = params[:year]
    @freecen_pieces = FreecenPiece.chapman_code(@chapman_code).year(@year).order_by(piece_number: 1)
  end

  def destroy
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No piece identified') && return if params[:id].blank?

    get_user_info_from_userid
    @freecen_piece = FreecenPiece.where('_id' => params[:id]).first
    if @freecen_piece.present?
      @freecen_piece.delete
      flash[:notice] = 'Piece destroyed'
    else
      flash[:notice] = 'Piece does not exist'
    end
    redirect_to freecen_pieces_path
  end

  def edit
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No piece identified') && return if params[:id].blank?

    get_user_info_from_userid
    @freecen_piece = FreecenPiece.where('_id' => params[:id]).first
    if @freecen_piece.blank?
      flash[:notice] = 'Piece does not exist'
      redirect_to freecen_pieces_path
    end
  end

  def index
    get_user_info_from_userid
    if session[:chapman_code].present?
      @freecen_pieces = FreecenPiece.chapman_code(session[:chapman_code]).order_by(year: 1, piece_number: 1)
      @chapman_code = session[:chapman_code]
      @totals_pieces, @totals_pieces_online, @totals_individuals, @totals_dwellings = FreecenPiece.county_year_totals(@chapman_code)
      @grand_totals_pieces, @grand_totals_pieces_online, @grand_totals_individuals, @grand_totals_dwellings = FreecenPiece.grand_totals(@totals_pieces, @totals_pieces_online, @totals_individuals, @totals_dwellings)
    else
      redirect_to manage_resources_path && return
    end
  end

  def new
    get_user_info_from_userid
    @freecen_piece = FreecenPiece.new
    @freecen_piece.year = params[:year] if params[:year].present? &&
      Freecen::CENSUS_YEARS_ARRAY.include?(params[:year])
    @freecen_piece.chapman_code = params[:chapman_code].upcase if params[:chapman_code].present?
    @freecen_piece.subplaces = [{ 'name' => '', 'lat' => '0.0', 'long' => '0.0' }]
    places = Freecen2Place.chapman_code(params[:chapman_code].upcase).order_by(place_name: 1) if params[:chapman_code].present?
    @places = []
    places.each do |place|
      @places << place.place_name
    end
    @years = Freecen::CENSUS_YEARS_ARRAY
  end

  def select_new_county
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No year identified') && return unless Freecen::CENSUS_YEARS_ARRAY.include?(params[:year])

    @county = ''
    @year = params[:year]
    year_pieces = FreecenPiece.only(:chapman_code).where('year' => @year).entries
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
    @freecen_piece = FreecenPiece.where('_id' => params[:id])
    @freecen_piece = @freecen_piece.first if @freecen_piece.present?
    @chapman_code = session[:chapman_code]
  end

  def update
    # puts "\n\n*** update ***\n"
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No information in the update') && return if params[:id].blank? || params[:freecen_piece].blank?

    @freecen_piece = FreecenPiece.where('_id' => params[:id]).first
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Piece not found') && return if @freecen_piece.blank?

    @new_piece_params = FreecenPiece.transform_piece_params(params[:freecen_piece])
    @piece_params_errors = FreecenPiece.check_piece_params(@new_piece_params, controller_name)
    redirect_to(edit_freecen_piece_path(@freecen_piece.id), notice: "Could not update the piece #{@piece_params_errors}") if @piece_params_errors.present? && @piece_params_errors.any?

    # update the fields
    #online_time not editable by coords for now
    #num_individuals not editable by coords for now
    success, place_params = FreecenPiece.set_piece_place(@freecen_piece)
    @new_piece_params = @new_piece_params.merge(place_params) if success
    result = @freecen_piece.update(@new_piece_params) if success
    unless result
      flash[:notice] = "Could not update the piece #{@freecen_piece.errors}"
      render :edit && return
    end
    # bust database coverage cache so it picks up the change for display
    Rails.cache.delete('freecen_coverage_index')
    flash[:notice] = 'Update was successful'
    if session[:manage_user_origin] == 'manage county'
      redirect_to freecen_piece_path(@freecen_piece.id)
    else
      next_page = freecen_coverage_path + "/#{@freecen_piece.chapman_code}##{@freecen_piece.year}"
      redirect_to next_page
    end
  end

  private

  def freecen_piece_params
    params.require(:freecen_piece).permit!
  end
end
