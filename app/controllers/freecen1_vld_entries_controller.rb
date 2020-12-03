class Freecen1VldEntriesController < ApplicationController
  skip_before_action :require_login

  def index
    get_user_info_from_userid
    @freecen1_vld_entries = Freecen1VldEntry.where(freecen1_vld_file_id: params[:file]).order_by(dwelling_number: 1, sequence_in_household: 1).page(params[:page]).per(50)
    @freecen1_vld_file = Freecen1VldFile.find(params[:file])
    session.delete(:freecen1_vld_file)
  end

  def show
    get_user_info_from_userid
    if params[:id].present?
      @freecen1_vld_entry = Freecen1VldEntry.find(params[:id])
      @chapman_code = session[:chapman_code]
      @freecen1_vld_file = Freecen1VldFile.find(params[:file])
    end
    redirect_to manage_resources_path && return
  end
end
