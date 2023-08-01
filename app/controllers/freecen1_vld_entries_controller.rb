class Freecen1VldEntriesController < ApplicationController
  skip_before_action :require_login, only: [:show]


  def edit_pob
    get_user_info_from_userid
    if params[:id].present?
      @freecen1_vld_entry = Freecen1VldEntry.find(params[:id])
      @counties = ChapmanCode.freecen_birth_codes
    else
      flash[:notice] = 'An id for the display of the entry does not exist'
      redirect_to new_manage_resource_path && return
    end
  end

  def index
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No file identified') && return if params[:file].blank?
    get_user_info_from_userid
    if session[:vld_pob_val].present? && session[:vld_pob_val] = true
      @freecen1_vld_entries = Freecen1VldEntry.where(freecen1_vld_file_id: params[:file], pob_valid: false).order_by(dwelling_number: 1, sequence_in_household: 1)
    else
      @freecen1_vld_entries = Freecen1VldEntry.where(freecen1_vld_file_id: params[:file]).order_by(dwelling_number: 1, sequence_in_household: 1)
    end
    @freecen1_vld_file = Freecen1VldFile.find(params[:file])
    session.delete(:freecen1_vld_file)
  end

  def override_pob_status
    if params[:id].present?
      @freecen1_vld_entry = Freecen1VldEntry.find(params[:id])

      @freecen1_vld_entry.update_attributes(pob_warning: '', pob_valid: 'true')
      message = "The override of the POB Status for Dwelling Number:#{@freecen1_vld_entry.dwelling_number} Sequence in Household:#{@freecen1_vld_entry.sequence_in_household} (#{@freecen1_vld_entry.forenames} #{@freecen1_vld_entry.surname}) was successful"

      flash[:notice] = message
      redirect_to(manual_validate_pobs_freecen1_vld_file_path(id: @freecen1_vld_entry.freecen1_vld_file_id)) && return

    else
      flash[:notice] = 'An id for the display of the entry does not exist'
      redirect_to new_manage_resource_path && return
    end
  end

  def propagate_pob
    message = "**** Propagate POB under contruction ****"
    redirect_to new_manage_resource_path && return
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

  def update
    get_user_info_from_userid
    if params[:id].present?
      @freecen1_vld_entry = Freecen1VldEntry.find(params[:id])
      @freecen1_vld_file = Freecen1VldFile.find(@freecen1_vld_entry.freecen1_vld_file_id)
      vld_year = @freecen1_vld_file.full_year
      result, warning = Freecen1VldEntry.valid_pob?(vld_year, params[:freecen1_vld_entry][:verbatim_birth_county], params[:freecen1_vld_entry][:verbatim_birth_place], params[:freecen1_vld_entry][:birth_county], params[:freecen1_vld_entry][:birth_place])
      if result
        @freecen1_vld_entry.add_freecen1_vld_entry_edit(@user.userid, 'Manual Val Edit', @freecen1_vld_entry.verbatim_birth_county, @freecen1_vld_entry.verbatim_birth_place, @freecen1_vld_entry.birth_county, @freecen1_vld_entry.birth_place, @freecen1_vld_entry.notes)
        @freecen1_vld_entry.update_attributes(params[:freecen1_vld_entry])
        Freecen1VldEntry.update_linked_records_pob(@freecen1_vld_entry,  params[:freecen1_vld_entry][:birth_county], params[:freecen1_vld_entry][:birth_place],  params[:freecen1_vld_entry][:notes])
        @freecen1_vld_entry.update_attributes(pob_valid: result, pob_warning: warning)
        @freecen1_vld_entry.reload
        flash[:notice] = "**** EDIT SUBMIT (UPDATE) - under construction (POB validation result = #{result} / #{warning})****"
        # if values changed offer propagation
        #
        #flash[:notice] = 'The Edit was successful'
        #redirect_to(manual_validate_pobs_freecen1_vld_file_path(id: @freecen1_vld_entry.freecen1_vld_file_id)) && return
      else
        flash[:notice] = "The Update failed as the POB(s) are still invalid"
      end
      redirect_to(edit_pob_freecen1_vld_entry_path(id: params[:id])) && return

    else
      flash[:notice] = 'An id for the display of the entry does not exist'
      redirect_to new_manage_resource_path && return
    end
  end


end
