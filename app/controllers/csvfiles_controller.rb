class CsvfilesController < ApplicationController

  require 'freereg_csv_update_processor'
  require 'digest/md5'


  def create
    # There can be two types of creation firstly for an Upload of a new file and secondly from the Replacement of an exiting file.
    #processing is slightly different depending upon the type
    if params[:csvfile].blank? || params[:csvfile][:csvfile].blank?
      flash[:notice] = 'You must select a file'
      redirect_to :back
      return
    end
    get_user_info_from_userid
    @csvfile  = Csvfile.new(csvfile_params)
    #if the process does not have a userid then the process has been initiated by the user on his own batches
    @csvfile.userid = session[:userid]   if params[:csvfile][:userid].nil?
    @csvfile.file_name = @csvfile.csvfile.identifier
    if params[:commit] == "Replace"
      name_ok = @csvfile.check_name(session[:file_name])
      if !name_ok
        flash[:notice] = 'The file you are replacing must have the same name'
        session.delete(:file_name)
        redirect_to :back
        return
      else
        setup = @csvfile.setup_batch
        if !setup[0]
          flash[:notice] = setup[1]
          session.delete(:file_name)
          redirect_to :back
          return
        else
          batch = setup[1]
        end
      end
    end
    #lets check for existing file, save if required
    proceed = @csvfile.check_for_existing_file
    @csvfile.save if proceed
    if @csvfile.errors.any?
      flash[:notice] = "The upload with file name #{@csvfile.file_name} was unsuccessful because #{@csvfile.errors.messages}"
      get_userids_and_transcribers
      redirect_to :back
      return
    end #error
    batch = @csvfile.create_batch_unless_exists
    processing_time = @csvfile.estimate_time
    range = File.join(@csvfile.userid,@csvfile.file_name)
    batch = PhysicalFile.where(:userid => @csvfile.userid, :file_name => @csvfile.file_name,:waiting_to_be_processed => true).first
    if batch.present?
      flash[:notice] = "Your file is currently waiting to be processed. It cannot be processed this way now"
      logger.warn("FREEREG:CSV_FAILURE: Attempt to double process #{@csvfile.userid} #{@csvfile.file_name}")
    else
      batch = PhysicalFile.where(:userid => @csvfile.userid, :file_name => @csvfile.file_name).first
      case
      when @user.person_role == "trainee"
        pid1 = Kernel.spawn("rake build:freereg_new_update[\"no_search_records\",\"individual\",\"no\",#{range}]")
        flash[:notice] =  "The csv file #{ @csvfile.file_name} is being checked. You will receive an email when it has been completed."
      when processing_time < 600
        batch.update_attributes(:waiting_to_be_processed => true, :waiting_date => Time.now)
        #check to see if rake task running
        rake_lock_file = File.join(Rails.root,"tmp","processing_rake_lock_file.txt")
        if File.exist?(rake_lock_file)
          p "lock existed"
          flash[:notice] =  "The csv file #{ @csvfile.file_name} has been sent for processing . You will receive an email when it has been completed."
        else
          p "Creating lock"
          p rake_lock_file
          locking_file = File.new(rake_lock_file, "w")
          logger.warn("FREEREG:CSV_PROCESSING: Spinning off rake task for #{@csvfile.userid} #{@csvfile.file_name}")
          pid1 = Kernel.spawn("rake build:freereg_new_update[\"create_search_records\",\"waiting\",\"no\",\"a-9\"]")
          flash[:notice] =  "The csv file #{ @csvfile.file_name} is being processed . You will receive an email when it has been completed."
        end
      when processing_time >= 600
        flash[:notice] =  "The file has been queued it is too large to be processed normally. The data manager has been informed and will discuss with you how it may be scheduled for processing. "
        UserMailer.report_to_data_manger_of_large_file( @csvfile.file_name,@csvfile.userid).deliver_now
      end
    end
    @csvfile.delete
    if session[:my_own]
      redirect_to my_own_freereg1_csv_file_path
      return
    end #session
    unless session[:freereg1_csv_file_id].nil?
      redirect_to freereg1_csv_files_path(:anchor => "#{session[:freereg1_csv_file_id]}")
      return
    else
      redirect_to freereg1_csv_files_path
      return
    end
  end #create method




  def delete
    @role = session[:role]
    @csvfile  = Csvfile.new(:userid  => session[:userid])
    freefile = Freereg1CsvFile.find(params[:id])
    @csvfile.file_name = freefile.file_name
    @csvfile.freereg1_csv_file_id = freefile._id
    @csvfile.save_to_attic
    @csvfile.delete
    redirect_to my_own_freereg1_csv_file_path(:anchor =>"#{session[:freereg1_csv_file_id]}"),notice: "The csv file #{freefile.file_name} has been deleted."
  end

  def edit
    #code to move existing file to attic
    @file = Freereg1CsvFile.id(params[:id]).first
    if @file.present?
      get_user_info_from_userid
      @person = @file.userid
      @file_name = @file.file_name
      #there can be multiple batches only one of which might be locked
      Freereg1CsvFile.where(:userid => @person,:file_name => @file_name).each do |file|
        if file.locked_by_transcriber ||  file.locked_by_coordinator
          flash[:notice] = 'The replacement of the file is not permitted as it has been locked due to on-line changes; download the updated copy and remove the lock'
          redirect_to :back
          return
        end
      end
      @csvfile  = Csvfile.new(:userid  => @person, :file_name => @file_name)
      session[:file_name] =  @file_name
      get_userids_and_transcribers
    else
      flash[:notice] = "There was no file to replace"
      redirect_to :back
      return
    end
  end


  def get_userids_and_transcribers
    syndicate = @user.syndicate
    syndicate = session[:syndicate] unless session[:syndicate].nil?
    @people = Array.new
    @people <<  @user.userid
    case
    when  @user.person_role == 'country_coordinator' || @user.person_role == 'county_coordinator'  || @user.person_role == 'system_administrator' ||  @user.person_role == 'volunteer_coordinator' ||  @user.person_role == 'data_manager'
      @userids = UseridDetail.all.order_by(userid_lower_case: 1)
      load_people(@userids)
    when  @user.person_role == 'country_coordinator' || @user.person_role == 'county_coordinator'  || @user.person_role == 'syndicate_coordinator'
      @userids = UseridDetail.syndicate(syndicate).all.order_by(userid_lower_case: 1)
      load_people(@userids)
    else
      @userids = @user
    end #end case
  end

  def load_people(userids)
    userids.each do |ids|
      @people << ids.userid
    end
  end

  def new
    #get @userid
    get_user_info_from_userid
    #Lets create for the user and change later
    @csvfile  = Csvfile.new(:userid  => session[:userid])
    #get @people
    get_userids_and_transcribers
  end

  private
  def csvfile_params
    params.require(:csvfile).permit!
  end
end
