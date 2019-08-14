class Freecen1VldFilesController < ApplicationController
  skip_before_action :require_login

  def index
    if session[:chapman_code].present?
      @freecen1_vld_files = Freecen1VldFile.chapman(session[:chapman_code]).order_by(full_year: 1, piece: 1).page(params[:page]).per(25)
      @chapman_code = session[:chapman_code]
    else
      redirect_to manage_resources_path && return
    end
  end

  def show
    if params[:id].present?
      @freecen1_vld_file = Freecen1VldFile.find(params[:id])
      @chapman_code = session[:chapman_code]
    end
    redirect_to manage_resources_path && return
  end
end
