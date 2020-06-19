class Freecen2DistrictsController < ApplicationController
  require 'freecen_constants'

  def index
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No Chapman code or year') && return if params[:chapman_code].blank? || params[:year].blank?

    get_user_info_from_userid
    @freecen2_districts = Freecen2District.chapman_code(params[:chapman_code]).year(params[:year]).order_by(name: 1)
  end

  def show
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No District identified') && return if params[:id].blank?

    get_user_info_from_userid
    @freecen2_district = Freecen2District.find_by(id: params[:id])
    @place = @freecen2_district.freecen2_place
    @chapman_code = session[:chapman_code]
  end
end
