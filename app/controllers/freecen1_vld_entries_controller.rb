class Freecen1VldEntriesController < ApplicationController
  skip_before_action :require_login, only: [:show]

  def index
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No file identified') && return if params[:file].blank?
    get_user_info_from_userid
    @freecen1_vld_entries = Freecen1VldEntry.where(freecen1_vld_file_id: params[:file]).order_by(dwelling_number: 1, sequence_in_household: 1)
    @freecen1_vld_file = Freecen1VldFile.find(params[:file])
    session.delete(:freecen1_vld_file)
  end

  def show
    get_user_info_from_userid
    if params[:id].present?
      @freecen1_vld_entry = Freecen1VldEntry.find(params[:id])
      @chapman_code = session[:chapman_code]
      @freecen1_vld_file = Freecen1VldFile.find(params[:file])
    else
      flash[:notice] = 'An id for the display of the entry does not exist'
      redirect_to new_manage_resource_path && return
    end
  end
end
