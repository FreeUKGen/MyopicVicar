class Freecen1VldEntriesController < ApplicationController
  skip_before_action :require_login, only: [:show]

  ActionController::Parameters.permit_all_parameters = true

  def edit_pob
    get_user_info_from_userid
    if params[:id].present?
      @freecen1_vld_entry = Freecen1VldEntry.find(params[:id])
      @counties = ChapmanCode.freecen_birth_codes
      @counties.sort!
    else
      flash[:notice] = 'An id for the edit of the entry does not exist'
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

  def propagate_pob
    if params[:commit] == 'Submit'
      # session.delete[:prop_pob_fields] if session[:prop_pob_fields].present?
      p "AEV01 #{params.inspect}"
      flash[:notice] = 'Propagation submitted'
      redirect_to new_manage_resource_path && return

    else
      get_user_info_from_userid
      if params[:id].present?
        @freecen1_vld_entry = Freecen1VldEntry.find(params[:id])
        @verbatim_birth_county = @freecen1_vld_entry.verbatim_birth_county
        @verbatim_birth_place = @freecen1_vld_entry.verbatim_birth_place
        @birth_county = @freecen1_vld_entry.birth_county
        @birth_place = @freecen1_vld_entry.birth_place
        @birth_notes = @freecen1_vld_entry.notes
        @propagation_scope = ''
        @propagation_fields = params[:fields]
        p "AEV02 #{params.inspect}"
      else
        flash[:notice] = 'An id for the propagation of the entry does not exist'
        redirect_to new_manage_resource_path && return
      end
    end
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
      reason = 'Manual Val Edit'
      case params[:commit]

      when 'Propagate Alternative Fields'
        session.delete(:propagate_pob) if session[:propagate_pob].present?
        session[:prop_pob_fields] = 'Propagate Alternative Fields'
        redirect_to(propagate_pob_freecen1_vld_entry_path(id: params[:id], fields: 'Propagate Alternative Fields')) && return

      when 'Propagate Notes'
        session.delete(:propagate_pob) if session[:propagate_pob].present?
        session[:prop_pob_fields] = 'Propagate Notes'
        redirect_to(propagate_pob_freecen1_vld_entry_path(id: params[:id])) && return

      when 'Propagate Both'
        session.delete(:propagate_pob) if session[:propagate_pob].present?
        session[:prop_pob_fields] = 'Propagate Alternative Fields & Notes'
        redirect_to(propagate_pob_freecen1_vld_entry_path(id: params[:id])) && return

      when 'Accept'
        result = true
        warning = ''
        reason = 'Manual Val Accept'
      else
        result, warning = Freecen1VldEntry.valid_pob?(vld_year, params[:freecen1_vld_entry][:verbatim_birth_county], params[:freecen1_vld_entry][:verbatim_birth_place], params[:freecen1_vld_entry][:birth_county], params[:freecen1_vld_entry][:birth_place])
      end
      if result
        verbatim_changed, alternative_changed, notes_changed = @freecen1_vld_entry.edits_made?(params[:freecen1_vld_entry])
        if verbatim_changed || alternative_changed || notes_changed
          @freecen1_vld_entry.add_freecen1_vld_entry_edit(@user.userid, reason, @freecen1_vld_entry.verbatim_birth_county, @freecen1_vld_entry.verbatim_birth_place, @freecen1_vld_entry.birth_county, @freecen1_vld_entry.birth_place, @freecen1_vld_entry.notes)
          @freecen1_vld_entry.update_attributes(params[:freecen1_vld_entry])
          Freecen1VldEntry.update_linked_records_pob(@freecen1_vld_entry,  params[:freecen1_vld_entry][:birth_county], params[:freecen1_vld_entry][:birth_place],  params[:freecen1_vld_entry][:notes])
        end
        @freecen1_vld_entry.update_attributes(pob_valid: result, pob_warning: warning)
        @freecen1_vld_entry.reload
        session[:propagate_pob] = @freecen1_vld_entry.id
        flash[:notice] = "The Update was successful - Please specify Propagation Requirements"
        # if values changed offer propagation
        #
        #flash[:notice] = 'The Edit was successful'
        #redirect_to(manual_validate_pobs_freecen1_vld_file_path(id: @freecen1_vld_entry.freecen1_vld_file_id)) && return
      else
        flash[:notice] = "The Update failed as POB (#{params[:freecen1_vld_entry][:birth_county]} #{params[:freecen1_vld_entry][:birth_place]}) is invalid"
      end
      redirect_to(edit_pob_freecen1_vld_entry_path(id: params[:id])) && return

    else
      flash[:notice] = 'An id for the display of the entry does not exist'
      redirect_to new_manage_resource_path && return

    end
  end

  private

  def freecen1_vld_entry_params
    params.require(:freecen1_vld_entry).permit!
  end
end
