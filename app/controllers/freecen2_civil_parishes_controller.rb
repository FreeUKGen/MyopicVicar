class Freecen2CivilParishesController < ApplicationController
  require 'freecen_constants'
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
    @freecen2_civil_parish.freecen2_hamlets
  end
end
