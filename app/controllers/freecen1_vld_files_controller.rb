class Freecen1VldFilesController < ApplicationController

  require 'digest/md5'

  def auto_validate_pobs
    if params[:id].present?
      vldfile = Freecen1VldFile.find(params[:id])
    else
      message = 'The file was not correctly linked. Have your coordinator contact the Web Master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    # seems to be able to process about 1000 records per min on local server and about 4000 per min on TEST3
    per_min = 4000
    run_time_estimate = (vldfile.num_individuals.to_f / per_min).to_f.round(0).to_s
    run_time_estimate = '1' if run_time_estimate == '0'

    get_user_info_from_userid
    vldfile.auto_validate_pobs(@user.userid)

    message = "Started Automatic Validation of POBs for #{vldfile.file_name} - you will receive an email when it has completed (estimated runtime = #{run_time_estimate} mins)"
    redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
  end

  def create
    # Initial guards
    redirect_back(fallback_location: new_freecen1_vld_file_path, notice: 'You must select a file') && return if params[:freecen1_vld_file].blank? || params[:freecen1_vld_file][:uploaded_file].blank?

    params[:freecen1_vld_file][:dir_name] = session[:chapman_code]

    @vldfile = Freecen1VldFile.find_by(dir_name: session[:chapman_code], file_name: params[:freecen1_vld_file][:uploaded_file].original_filename)
    if @vldfile.present?
      @vldfile.update_attributes(freecen1_vld_file_params)
      @vldfile.set(num_invalid_pobs: nil)
    else
      @vldfile = Freecen1VldFile.new(freecen1_vld_file_params)
    end
    @vldfile.uploaded_file_name = @vldfile.uploaded_file.identifier
    redirect_back(fallback_location: new_freecen1_vld_file_path, notice: 'That file exists please use the replace action') && return if @vldfile.check_exists_on_upload && session[:replace].blank?

    redirect_back(fallback_location: new_freecen1_vld_file_path, notice: 'That is not the same file name') && return if session[:replace].present? && session[:replace] != @vldfile.uploaded_file_name

    redirect_back(fallback_location: new_freecen1_vld_file_path, notice: 'That is not a VLD file') && return unless @vldfile.check_extension

    session.delete(:replace)
    logger.warn("#{appname_upcase}:VLD_PROCESSING: #{@vldfile.uploaded_file}")
    result = @vldfile.save
    # deliberate crash if ther save fails
    p @vldfile.errors.full_messages unless result
    crash unless result

    @vldfile.update_attributes(uploaded_file_location: @vldfile.uploaded_file.file.file, userid: session[:userid])
    session.delete(:file_name) if session[:file_name].present?
    proceed, message = @vldfile.process_the_batch
    unless proceed
      logger.warn("#{appname_upcase}:VLD_PROCESSING: " + message)
      Freecen1VldFile.where(dir_name: session[:chapman_code], :file_name.exists => false).each do |empty_file|
        empty_file.delete
      end
      redirect_back(fallback_location: new_freecen1_vld_file_path, notice: message) && return
    end
    Freecen1VldFile.where(dir_name: session[:chapman_code], :file_name.exists => false).each do |empty_file|
      empty_file.delete
    end
    flash[:notice] = message
    flash.keep
    redirect_to(freecen1_vld_files_path(anchor: "#{session[:freecen1_vld_file_id]}")) && return
  end

  def csv_download
    get_user_info_from_userid
    @freecen1_vld_file = Freecen1VldFile.find(params[:id])
    unless Freecen1VldFile.valid_freecen1_vld_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the Web Manager'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    success, message, file_location, file_name = @freecen1_vld_file.create_csv_file
    if success
      if File.file?(file_location)
        send_file(file_location, filename: file_name, x_sendfile: true) && return
      end
    else
      flash[:notice] = "There was a problem saving the file prior to download. Please send this message #{message} to your coordinator"
    end
    redirect_back(fallback_location: new_manage_resource_path) && return
  end

  def download_vld_file
    file = Freecen1VldFile.find(params[:file])
    redirect_back(fallback_location: select_userid_attic_files_path, notice: 'The file does not exist!') && return if file.blank?

    vld_file = File.join(Rails.application.config.vld_file_locations, file.dir_name, file.file_name)

    send_file(vld_file, filename: file.file_name) && return if File.exist?(vld_file)

    flash[:notice] = "The physical file #{file.file_name} does not exist, please contact the Web Manager."
    redirect_back(fallback_location: new_manage_resource_path) && return
  end

  def destroy
    vldfile = Freecen1VldFile.find(params[:id])
    if vldfile.present? && vldfile.dir_name.present? && vldfile.file_name.present?
      file_name = vldfile.file_name
      dir_name = vldfile.dir_name
      if vldfile.action.present?
        loaded_date = vldfile.u_at
      else
        loaded_date = ''
      end
      Freecen1VldFile.delete_freecen1_vld_entries(dir_name, file_name)
      Freecen1VldFile.delete_dwellings(dir_name, file_name)
      Freecen1VldFile.delete_individuals(dir_name, file_name)  # has callback to delete search records too
      Freecen1VldFile.save_to_attic(dir_name, file_name)
      piece = vldfile.freecen_piece
      if piece.present?
        piece.update_attributes(num_dwellings: 0, num_individuals: 0, num_entries: 0, freecen1_filename: '', status: '', status_date: '')
        piece.freecen1_vld_files.delete(vldfile)
        freecen2_piece = piece.freecen2_piece
        freecen2_piece_id = freecen2_piece.id
        freecen2_piece.freecen1_vld_files.delete(vldfile) if freecen2_piece.present?
        freecen2_piece.update_parts_status_on_file_deletion(vldfile, piece)
        freecen2_place = vldfile.freecen2_place
        if freecen2_place.present?
          freecen2_place.freecen1_vld_files.delete(vldfile)
          freecen2_district = vldfile.freecen2_district
          freecen2_district.freecen1_vld_files.delete(vldfile) if freecen2_district.present?
          freecen2_place.update_data_present_after_vld_delete(freecen2_piece)
          Freecen2PlaceCache.refresh(freecen2_place.chapman_code)
        end
      end
    end
    if vldfile.present?
      get_user_info_from_userid
      who = @user.userid
      Freecen1VldFile.create_audit_record(vldfile, who, loaded_date, freecen2_piece_id)
      vldfile.delete
    end
    redirect_to freecen1_vld_files_path, notice: "The vld file #{file_name} has been deleted."
  end

  def edit
    get_user_info_from_userid
    if params[:id].present?
      @freecen1_vld_file = Freecen1VldFile.find(params[:id])
      @chapman_code = session[:chapman_code]
    end
    unless Freecen1VldFile.valid_freecen1_vld_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    load_people
    if params[:type].present?
      @type = params[:type]
    else
      @type = 'all'
    end
    redirect_to new_manage_resource_path && return
  end

  def edit_civil_parishes
    case
    when params[:commit] == 'Submit'

      if  params[:editcivilparish][:old_civil_parish_name].present? &&
          params[:new_civil_parish_name].present?
        old_ed_cp_split = params[:editcivilparish][:old_civil_parish_name].split(' -- ')
        enum_dist = old_ed_cp_split[0]
        old_cp = old_ed_cp_split[1]
        if old_cp == params[:new_civil_parish_name]
          message = "The new Civil Parish name (#{params[:new_civil_parish_name]}) is the same as the existing Civil Parish name (#{old_cp}), so no update is required."
          redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
        end
      end

      if params[:vld_file_id].present?
        vldfile = Freecen1VldFile.find(params[:vld_file_id])
      else
        message = 'The file was not correctly linked. Have your coordinator contact the Web Master'
        redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
      end

      result = Freecen1VldEntry.collection.find({ freecen1_vld_file_id: vldfile.id, civil_parish: old_cp, enumeration_district: enum_dist }).update_many({"$set" => { :civil_parish => params[:new_civil_parish_name] } })
      result = FreecenDwelling.collection.find({ freecen1_vld_file_id: vldfile.id, civil_parish: old_cp, enumeration_district: enum_dist }).update_many({"$set" => { :civil_parish => params[:new_civil_parish_name] } })

      message = "The edit for Enumeration District #{enum_dist} - Civil Parish name '#{old_cp}' to '#{params[:new_civil_parish_name]}' was successful."
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    else
      get_user_info_from_userid
      if params[:id].present?
        @freecen1_vld_file = Freecen1VldFile.find(params[:id])
        @chapman_code = session[:chapman_code]
      end
      unless Freecen1VldFile.valid_freecen1_vld_file?(params[:id])
        message = 'The file was not correctly linked. Have your coordinator contact the Web Master'
        redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
      end
      load_people
      @type = params[:type].presence || 'all'

      @civil_parishes = SortedSet.new
      all_civil_parishes = Freecen1VldEntry.where(:freecen1_vld_file_id => params[:id]).pluck(:enumeration_district, :civil_parish)
      all_civil_parishes.each do |cp|
        @civil_parishes << "#{cp[0]} -- #{cp[1]}" if cp.present?
      end
      redirect_to new_manage_resource_path && return
    end
  end


  def entry_csv_download
    get_user_info_from_userid
    @freecen1_vld_file = Freecen1VldFile.find(params[:id])
    unless Freecen1VldFile.valid_freecen1_vld_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    success, message, file_location, file_name = @freecen1_vld_file.create_entry_csv_file
    if success
      if File.file?(file_location)
        send_file(file_location, filename: file_name, x_sendfile: true) && return
      end
    else
      flash[:notice] = "There was a problem saving the file prior to download. Please send this message #{message} to your coordinator"
    end

    redirect_back(fallback_location: new_manage_resource_path) && return
  end

  def index
    get_user_info_from_userid
    if session[:chapman_code].blank?
      flash[:notice] = 'A Chapman Code has not been set for the display of Freecen vld files does not exist'
      redirect_to new_manage_resource_path && return
    end
    @freecen1_vld_files = Freecen1VldFile.chapman(session[:chapman_code]).order_by(full_year: 1, piece: 1)
    @chapman_code = session[:chapman_code]
    session[:type] = 'vld_file_audit_index'
    session[:vld_pob_val] = false
  end

  def list_invalid_civil_parishes
    userid = session[:userid]
    chapman_code = session[:chapman_code]

    logger.warn("FREECEN:VLD_INVALID_CIVIL_PARISH_LISTING: Starting rake task for #{userid} county #{chapman_code}")
    pid1 = spawn("bundle exec rake list_vld_files_with_invalid_civil_parish[#{chapman_code},,#{userid}]")
    logger.warn("FREECEN:VLD_INVALID_CIVIL_PARISH_LISTING: rake task for #{pid1}")
    flash[:notice] = "The list of VLD files with invalid Civil Parish names for #{chapman_code} is being generated. You will receive an email when it has finished."
    redirect_to freecen1_vld_files_path
  end

  def manual_validate_pobs
    if params[:id].present?
      @freecen1_vld_file = Freecen1VldFile.find(params[:id])
    else
      message = 'The file was not correctly linked. Have your coordinator contact the Web Master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    session[:vld_pob_val] = true
    if @freecen1_vld_file.num_invalid_pobs.present?
      @num_invalid = @freecen1_vld_file.num_invalid_pobs
    else
      @num_invalid = Freecen1VldEntry.where(freecen1_vld_file_id: @freecen1_vld_file._id, pob_valid: false).count
    end
    redirect_to(freecen1_vld_entries_path(file: @freecen1_vld_file.id, num_invalid: @num_invalid))
  end

  def new
    get_user_info_from_userid
    @app = appname_downcase
    @action = 'Upload'
    session[:replace] = params[:replace]
    if session[:replace].present?
      dir_name = session[:chapman_code]
      file_name = session[:replace]
      file_location = File.join(Rails.application.config.vld_file_locations, dir_name, file_name)
      if File.file?(file_location)
        Freecen1VldFile.save_to_attic(dir_name, file_name)
      end
    end
    @vldfile = Freecen1VldFile.new(userid: session[:userid])
  end

  def update
    @freecen1_vld_file = Freecen1VldFile.find(params[:id])
    unless Freecen1VldFile.valid_freecen1_vld_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    @freecen1_vld_file.update_attributes(freecen1_vld_file_params)
    if @freecen1_vld_file.errors.any?
      load_people
      flash[:notice] = "The update was unsuccessful: #{message}"
      render action: 'edit'
      return
    else
      flash[:notice] = 'The update was successful'
      redirect_to(action: 'show') && return
    end
  end

  def show
    get_user_info_from_userid
    if params[:id].present?
      @freecen1_vld_file = Freecen1VldFile.find(params[:id])
      @chapman_code = session[:chapman_code]
    end
    redirect_to new_manage_resource_path && return
  end

  def load_people
    @people = []
    userids = UseridDetail.all.order_by(userid_lower_case: 1)
    userids.each do |ids|
      @people << ids.userid
    end
  end
  #........................................................................................... upload code

  private

  def freecen1_vld_file_params
    params.require(:freecen1_vld_file).permit!
  end
end
