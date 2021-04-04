class Freecen1VldFilesController < ApplicationController
  skip_before_action :require_login
  require 'digest/md5'

  def csv_download
    get_user_info_from_userid
    @freecen1_vld_file = Freecen1VldFile.find(params[:id])
    unless Freecen1VldFile.valid_freecen1_vld_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
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
    redirect_to manage_resources_path && return
  end

  def index
    get_user_info_from_userid
    if session[:chapman_code].present?
      @freecen1_vld_files = Freecen1VldFile.chapman(session[:chapman_code]).order_by(full_year: 1, piece: 1)
      @chapman_code = session[:chapman_code]
    else
      redirect_to manage_resources_path && return
    end
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
    redirect_to manage_resources_path && return
  end

  def load_people
    @people = []
    userids = UseridDetail.all.order_by(userid_lower_case: 1)
    userids.each do |ids|
      @people << ids.userid
    end
  end
  #........................................................................................... upload code


  def create
    # Initial guards
    redirect_back(fallback_location: new_freecen1_vld_file_path, notice: 'You must select a file') && return if params[:freecen1_vld_file].blank? || params[:freecen1_vld_file][:uploaded_file].blank?
    @vldfile = Freecen1VldFile.new(freecen1_vld_file_params)
    @vldfile.userid = params[:freecen1_vld_file][:userid].blank? ? session[:userid] : params[:freecen1_vld_file][:userid]
    redirect_back(fallback_location: new_freecen1_vld_file_path, notice: 'There was no userid') && return if @vldfile.userid.blank?

    @vldfile.save
    message = 'creation............................................................'
    logger.warn("#{appname_upcase}:VLD_PROCESSING: #{@vldfile.uploaded_file}" + message)

    redirect_back(fallback_location: new_freecen1_vld_file_path, notice: 'The file had an incorrect extension') && return unless @vldfile.check_extension

    @vldfile.update_attributes(uploaded_file_name: @vldfile.uploaded_file.filename, uploaded_file_location: @vldfile.uploaded_file.file.file)

    p @vldfile
    case params[:freecen1_vld_file][:action]
    when 'Replace'
      proceed, message = @vldfile.setup_batch_on_replace(session[:file_name])
    when 'Upload'
      proceed, message = @vldfile.setup_batch_on_upload
    end

    session.delete(:file_name) unless proceed
    unless proceed
      logger.warn("#{appname_upcase}:CSV_PROCESSING: " + message)
      flash[:notice] = message
      redirect_back(fallback_location: new_freecen1_vld_file_path, notice: message) && return

    end

    proceed, message = @vldfile.process_the_batch(@user)
    @vldfile.delete
    unless proceed
      logger.warn("#{appname_upcase}:CSV_PROCESSING: " + message)
      redirect_back(fallback_location: new_freecen1_vld_files_path, notice: message) && return

    end
    flash[:notice] = message
    flash.keep
    if session[:my_own] && appname_downcase == 'freecen'
      redirect_to(my_own_freecen1_vld_files_path) && return
    elsif session[:freecen1_vld_file_id].present?
      redirect_to(freecen_csv_files_path(anchor: "#{session[:freecen1_vld_file_id]}")) && return
    elsif appname_downcase == 'freecen'
      redirect_to(freecen1_vld_files_path) && return
    end
  end

  def delete
    @role = session[:role]
    @vldfile = Freecen1VldFile.new(userid: session[:userid])
    freefile = Freecen1VldFile.find(params[:id]) if appname_downcase == 'freecen'
    @vldfile.file_name = freefile.file_name
    @vldfile.file_id = freefile._id
    @vldfile.save_to_attic
    @vldfile.delete
    flash[:alert] = "The csv file #{freefile.file_name} has been deleted."
    redirect_to(my_own_freecen1_vld_files_path(anchor: "#{session[:freecen1_vld_file_id]}"))
  end

  def edit
    # code to move existing file to attic

    @file = Freecen1VldFile.find_by(_id: params[:id])
    redirect_back(fallback_location: new_freecen1_vld_file_path, notice: 'There was no file to replace') && return if @file.blank?

    get_user_info_from_userid
    @app = appname_downcase
    @person = @file.userid
    @file_name = @file.file_name
    # there can be multiple batches only one of which might be locked

    files = Freecen1VldFile.where(userid: @person, file_name: @file_name)
    files.each do |file|
      flash[:notice] = 'The replacement of the file is not permitted as it has been locked; download the updated copy to remove your lock. Note a coordinator lock can only be removed by the coordinator' if file.locked_by_transcriber || file.locked_by_coordinator
      redirect_back(fallback_location:  new_freecen1_vld_file_path) && return if file.locked_by_transcriber || file.locked_by_coordinator
    end
    @csvfile = Freecen1VldFile.new(userid: @person, file_name: @file_name)
    session[:file_name] = @file_name
    userids_and_transcribers
    @app = appname_downcase
    @action = 'Replace'

  end

  def load_people(userids)
    userids.each do |ids|
      @people << ids.userid
    end
  end

  def new
    get_user_info_from_userid
    @vldfile = Freecen1VldFile.new(userid: session[:userid])
    userids_and_transcribers
    @app = appname_downcase
    @action = 'Upload'
  end

  def userids_and_transcribers
    syndicate = @user.syndicate
    syndicate = session[:syndicate] unless session[:syndicate].nil?
    @people = []
    @people << @user.userid
    if session[:manage_user_origin] == 'manage syndicate'
      @userids = UseridDetail.syndicate(syndicate).all.order_by(userid_lower_case: 1)
      load_people(@userids)
    elsif %w[county_coordinator master_county_coordinator syndicate_coordinator country_coordinator system_administrator technical data_manager
             volunteer_coordinator documentation_coordinator executive_director project_manager].include?(@user.person_role)
      @userids = UseridDetail.all.order_by(userid_lower_case: 1)
      load_people(@userids)
    else
      @userids = @user
    end
  end

  private

  def freecen1_vld_file_params
    params.require(:freecen1_vld_file).permit!
  end
end
