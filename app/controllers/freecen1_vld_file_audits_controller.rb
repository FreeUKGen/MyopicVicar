class Freecen1VldFileAuditsController < ApplicationController

  # GET /freecen1_vld_file_audits
  def index
    @chapman_code =  session[:chapman_code]
    @syndicate =  session[:syndicate]
    @role = session[:role]
    @freecen1_vld_file_audits = Freecen1VldFileAudit.all
    if session[:chapman_code].blank?
      flash[:notice] = 'A Chapman Code has not been set for the display of Deleted Freecen vld files'
      redirect_to new_manage_resource_path && return
    end
    @freecen1_vld_file_audits = Freecen1VldFileAudit.chapman(session[:chapman_code]).order_by(c_at: -1)
  end

  private

  def freecen1_vld_file_audit_params
    params.require(:freecen1_vld_file_audit).permit!
  end
end
