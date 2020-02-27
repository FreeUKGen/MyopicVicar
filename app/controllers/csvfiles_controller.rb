class CsvfilesController < ApplicationController
  require 'digest/md5'

  def create
    # Initial guards
    redirect_back(fallback_location: new_csvfile_path, notice: 'You must select a file') && return if params[:csvfile].blank? || params[:csvfile][:csvfile].blank?

    get_user_info_from_userid
    @csvfile = Csvfile.new(csvfile_params)
    # if the process does not have a userid then the process has been initiated by the user on his own batches
    @csvfile.userid = session[:userid] if params[:csvfile][:userid].blank?
    redirect_back(fallback_location: new_csvfile_path, notice: 'There was no userid') && return if @csvfile.userid.blank?

    @csvfile.file_name = @csvfile.csvfile.identifier
    redirect_back(fallback_location: new_csvfile_path, notice: 'There was no file name') && return if @csvfile.file_name.blank?

    case params[:csvfile][:action]
    when 'Replace'
      proceed, message = @csvfile.setup_batch_on_replace(session[:file_name])
    when 'Upload'
      proceed, message = @csvfile.setup_batch_on_upload
    end

    session.delete(:file_name) unless proceed
    unless proceed
      logger.warn("#{appname_upcase}:CSV_PROCESSING: " + message)
      flash[:notice] = message
      redirect_back(fallback_location: new_csvfile_path, notice: message) && return

    end

    proceed, message = @csvfile.process_the_batch(@user)
    @csvfile.delete
    unless proceed
      logger.warn("#{appname_upcase}:CSV_PROCESSING: " + message)
      redirect_back(fallback_location: new_csvfile_path, notice: message) && return

    end
    flash[:notice] = message
    flash.keep
    if session[:my_own] && appname_downcase == 'freereg'
      redirect_to(my_own_freereg1_csv_file_path) && return
    elsif session[:my_own] && appname_downcase == 'freecen'
      redirect_to(my_own_freecen_csv_file_path) && return
    elsif session[:freereg1_csv_file_id].present?
      redirect_to(freereg1_csv_files_path(anchor: "#{session[:freereg1_csv_file_id]}")) && return
    elsif session[:freecen_csv_file_id].present?
      redirect_to(freecen_csv_files_path(anchor: "#{session[:freecen_csv_file_id]}")) && return
    elsif appname_downcase == 'freereg'
      redirect_to(freereg1_csv_files_path) && return
    elsif appname_downcase == 'freecen'
      redirect_to(freecen_csv_files_path) && return
    end
  end

  def delete
    @role = session[:role]
    @csvfile = Csvfile.new(userid: session[:userid])
    freefile = Freereg1CsvFile.find(params[:id]) if appname_downcase == 'freereg'
    freefile = FreecenCsvFile.find(params[:id]) if appname_downcase == 'freecen'
    @csvfile.file_name = freefile.file_name
    @csvfile.file_id = freefile._id
    @csvfile.save_to_attic
    @csvfile.delete
    flash[:notice] = "The csv file #{freefile.file_name} has been deleted."
    redirect_to(my_own_freereg1_csv_file_path(anchor: "#{session[:freereg1_csv_file_id]}"))  && return if appname_downcase == 'freereg'
    redirect_to(my_own_freereg1_csv_file_path(anchor: "#{session[:freereg1_csv_file_id]}"))  && return if appname_downcase == 'freecen'
  end

  def edit
    # code to move existing file to attic
    @file = Freereg1CsvFile.id(params[:id]).first if appname_downcase == 'freereg'
    @file = FreecenCsvFile.id(params[:id]).first if appname_downcase == 'freecen'
    redirect_back(fallback_location: new_csvfile_path, notice: 'There was no file to replace') && return if @file.blank?

    get_user_info_from_userid
    @person = @file.userid
    @file_name = @file.file_name
    # there can be multiple batches only one of which might be locked
    files = Freereg1CsvFile.where(userid: @person, file_name: @file_name) if appname_downcase == 'freereg'
    files = FreecenCsvFile.where(userid: @person, file_name: @file_name) if appname_downcase == 'freecen'
    files.each do |file|
      message = 'The replacement of the file is not permitted as it has been locked due to on-line changes; download the updated copy and remove the lock'
      redirect_back(fallback_location: new_csvfile_path, notice: message) && return if file.locked_by_transcriber || file.locked_by_coordinator

    end
    @csvfile = Csvfile.new(userid: @person, file_name: @file_name)
    session[:file_name] = @file_name
    userids_and_transcribers
    @action = 'Replace'
  end

  def load_people(userids)
    userids.each do |ids|
      @people << ids.userid
    end
  end

  def new
    get_user_info_from_userid
    @csvfile = Csvfile.new(userid: session[:userid])
    userids_and_transcribers
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
    elsif %w[county_coordinator syndicate_coordinator country_coordinator system_administrator technical data_manager volunteer_coordinator documentation_coordinator].include?(@user.person_role)
      @userids = UseridDetail.all.order_by(userid_lower_case: 1)
      load_people(@userids)
    else
      @userids = @user
    end
  end

  private

  def csvfile_params
    params.require(:csvfile).permit!
  end
end
