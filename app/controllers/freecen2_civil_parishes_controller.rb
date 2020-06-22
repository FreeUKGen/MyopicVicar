class Freecen2CivilParishesController < ApplicationController
  require 'freecen_constants'

  def edit
    redirect_back(fallback_location: new_manage_resource_path, notice:  'No civil parish identified') && return if params[:id].blank?

    get_user_info_from_userid
    @freecen2_civil_parish = Freecen2CivilParish.find_by(id: params[:id])
    @freecen2_place = @freecen2_civil_parish.freecen2_place
    @piece = @freecen2_civil_parish.freecen2_piece
    @chapman_code = @piece.district_chapman_code
    @freecen2_piece = @freecen2_civil_parish.piece_name
    places = Freecen2Place.chapman_code(@piece.district_chapman_code).all.order_by(place_name: 1)
    @places = []
    places.each do |place|
      @places << place.place_name
    end
    @freecen2_civil_parish.freecen2_hamlets.build
    @freecen2_civil_parish.freecen2_townships.build
    @freecen2_civil_parish.freecen2_wards.build
  end

  def index
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No Piece') && return if params[:piece_id].blank?

    get_user_info_from_userid
    @piece = Freecen2Piece.find_by(id: params[:piece_id])
    @freecen2_civil_parishes = Freecen2CivilParish.where(freecen2_piece_id: params[:piece_id]).order_by(:name.asc, :'freecen2_hamlets.name'.asc).all
  end

  def show
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No civil parish identified') && return if params[:id].blank?

    get_user_info_from_userid
    @freecen2_civil_parish = Freecen2CivilParish.find_by(id: params[:id])
    @place = @freecen2_civil_parish.freecen2_place
    @piece = @freecen2_civil_parish.freecen2_piece
    @chapman_code = @piece.district_chapman_code
    @freecen2_piece = @freecen2_civil_parish.piece_name
  end

  def update
    # puts "\n\n*** update ***\n"
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No information in the update') && return if params[:id].blank? || params[:freecen2_civil_parish].blank?

    @freecen2_civil_parish = Freecen2CivilParish.find_by(id: params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Civil Parish not found') && return if @freecen2_civil_parish.blank?

    @new_civil_parish_params = Freecen2Piece.transform_piece_params(params[:freecen2_piece])
    @piece_params_errors = Freecen2Piece.check_piece_params(@new_piece_params, controller_name)
    redirect_to(edit_freecen2_piece_path(@freecen2_piece.id), notice: "Could not update the piece #{@piece_params_errors}") if @piece_params_errors.present? && @piece_params_errors.any?

    # update the fields
    #online_time not editable by coords for now
    #num_individuals not editable by coords for now
    success, place_params = Freecen2Piece.set_piece_place(@freecen2_piece)
    @new_piece_params = @new_piece_params.merge(place_params) if success
    result = @freecen2_piece.update(@new_piece_params) if success
    unless result
      flash[:notice] = "Could not update the piece #{@freecen2_piece.errors}"
      render :edit && return
    end
    # bust database coverage cache so it picks up the change for display
    Rails.cache.delete('freecen_coverage_index')
    flash[:notice] = 'Update was successful'
    if session[:manage_user_origin] == 'manage county'
      redirect_to freecen2_piece_path(@freecen2_piece.id)
    else
      next_page = freecen_coverage_path + "/#{@freecen2_piece.chapman_code}##{@freecen2_piece.year}"
      redirect_to next_page
    end
  end
  private

  def freecen2_piece_params
    params.require(:freecen2_piece).permit!
  end
end
