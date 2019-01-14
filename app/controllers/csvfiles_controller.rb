class CsvfilesController < ApplicationController
  require 'digest/md5'

  def create
    # Initial guards
    redirect_to(:back, notice: 'You must select a file') and return if params[:csvfile].blank? || params[:csvfile][:csvfile].blank?

    get_user_info_from_userid
    @csvfile = Csvfile.new(csvfile_params)

    # if the process does not have a userid then the process has been initiated by the user on his own batches
    @csvfile.userid = session[:userid] if params[:csvfile][:userid].blank?
    redirect_to(:back, notice: 'There was no userid') and return if @csvfile.userid.blank?

    @csvfile.file_name = @csvfile.csvfile.identifier
    redirect_to(:back, notice: 'There was no file name') and return if @csvfile.file_name.blank?

    case params[:csvfile][:action]
    when 'Replace'
      proceed, message = @csvfile.file_replace_can_proceed(session[:file_name])
    when 'Upload'
      proceed, message = @csvfile.setup_batch_on_upload
    end
    session.delete(:file_name) unless proceed
    redirect_to(:back, notice: message) and return unless proceed
    proceed, message = @csvfile.process_the_batch(@user)
    flash[:notice] = message
    logger.warn('FREEREG:CSV_PROCESSING: ' + message)
    redirect_to(:back, notice: message) and return unless proceed
    @csvfile.delete

    redirect_to my_own_freereg1_csv_file_path and return if session[:my_own]

    redirect_to freereg1_csv_files_path(anchor: "#{session[:freereg1_csv_file_id]}") and return if session[:freereg1_csv_file_id].present?

    redirect_to freereg1_csv_files_path
  end

  def delete
    @role = session[:role]
    @csvfile = Csvfile.new(userid: session[:userid])
    freefile = Freereg1CsvFile.find(params[:id])
    @csvfile.file_name = freefile.file_name
    @csvfile.freereg1_csv_file_id = freefile._id
    @csvfile.save_to_attic
    @csvfile.delete
    redirect_to my_own_freereg1_csv_file_path(anchor: "#{session[:freereg1_csv_file_id]}"), notice: "The csv file #{freefile.file_name} has been deleted."
  end

  def edit
    # code to move existing file to attic
    @file = Freereg1CsvFile.id(params[:id]).first
    redirect_to(:back, notice: 'There was no file to replace') and return if @file.blank?

    get_user_info_from_userid
    @person = @file.userid
    @file_name = @file.file_name
    # there can be multiple batches only one of which might be locked
    Freereg1CsvFile.where(userid: @person, file_name: @file_name).each do |file|
      message = 'The replacement of the file is not permitted as it has been locked due to on-line changes; download the updated copy and remove the lock'
      redirect_to(:back, notice: message) and return if file.locked_by_transcriber || file.locked_by_coordinator
    end

    @csvfile = Csvfile.new(userid: @person, file_name: @file_name)
    session[:file_name] = @file_name
    get_userids_and_transcribers
    @action = 'Replace'
  end

  def get_userids_and_transcribers
    syndicate = @user.syndicate
    syndicate = session[:syndicate] unless session[:syndicate].nil?
    @people = []
    @people << @user.userid
    if session[:manage_user_origin] == 'manage syndicate'
      @userids = UseridDetail.syndicate(syndicate).all.order_by(userid_lower_case: 1)
      load_people(@userids)
    elsif @user.person_role == 'country_coordinator' || @user.person_role == 'county_coordinator'  || @user.person_role == 'system_administrator' ||  @user.person_role == 'volunteer_coordinator' ||  @user.person_role == 'data_manager'
      @userids = UseridDetail.all.order_by(userid_lower_case: 1)
      load_people(@userids)
    else
      @userids = @user
    end
  end

  def load_people(userids)
    userids.each do |ids|
      @people << ids.userid
    end
  end

  def new
    get_user_info_from_userid
    @csvfile = Csvfile.new(userid: session[:userid])
    get_userids_and_transcribers
    @action = 'Upload'
  end

  private

  def csvfile_params
    params.require(:csvfile).permit!
  end
end
