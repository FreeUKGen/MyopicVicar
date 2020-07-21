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
    redirect_back(fallback_location: manage_counties_path, notice: 'No information in the update') && return if params[:id].blank? || params[:freecen2_civil_parish].blank?

    @freecen2_civil_parish = Freecen2CivilParish.find_by(id: params[:id])
    redirect_back(fallback_location: manage_counties_path, notice: 'Civil Parish not found') && return if @freecen2_civil_parish.blank?

    chapman_code = @freecen2_civil_parish.freecen2_piece.district_chapman_code if @freecen2_civil_parish.freecen2_piece.present?
    place = Freecen2Place.find_by(chapman_code: chapman_code, place_name: params[:freecen2_civil_parish][:name]) if chapman_code.present?
    params[:freecen2_civil_parish][:freecen2_place_id] = place.id if place.present?
    @freecen2_civil_parish.update_attributes(freecen2_civil_parish_params)
    if @freecen2_civil_parish.errors.any?
      flash[:notice] = "The update of the civil parish failed #{@freecen_csv_entry.errors.full_messages}."
      redirect_back(fallback_location: edit_freecen2_civil_parish_path(@freecen2_civil_parish)) && return
    else
      flash[:notice] = 'Update was successful'
      redirect_to freecen2_civil_parish_path(@freecen2_civil_parish)
    end
  end

  private

  def freecen2_civil_parish_params
    params.require(:freecen2_civil_parish).permit!
  end
end
