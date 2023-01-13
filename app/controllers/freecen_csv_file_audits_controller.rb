class FreecenCsvFileAuditsController < ApplicationController

  # GET /freecen_csv_file_audits
  def index
    session[:type] = 'csv_file_audit_index'
    @chapman_code =  session[:chapman_code]
    @syndicate =  session[:syndicate]
    @role = session[:role]
    if session[:chapman_code].blank?
      flash[:notice] = 'A Chapman Code has not been set for the display of Deleted Freecen vld files'
      redirect_to new_manage_resource_path && return
    end
    @freecen_csv_file_audits = FreecenCsvFileAudit.chapman_code(session[:chapman_code]).order_by(c_at: -1)
  end

  private

  def freecen_csv_file_audit_params
    params.require(:freecen_csv_file_audit).permit!
  end
end
