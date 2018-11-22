class PhysicalFilesController < ApplicationController

  def all_files
    get_user_info_from_userid
    @selection  = 'all'
    @sorted_by = "All files by userid then batch name"
    session[:sorted_by] =  @sorted_by
    session[:who] = @selection
    session[:by_userid] = false
    @batches = PhysicalFile.all.order_by(userid: 1,batch_name: 1).page(params[:page]).per(1000)
    @number =  @batches.length
    @number =  @batches.length
    @has_access = ((@user.person_role == "data_manager") || (@user.person_role == "system_administrator"))
    @paginate = true
    render  'index'
  end

  def create
    case
    when params[:commit] == "Select Userid"
      #This is not the creation of a physical file but simply the selection of who and how to display the files
      if params[:physical_file][:type].present?
        session[:sorted_by] = params[:physical_file][:type]
        session[:who] = params[:physical_file][:userid]
        session[:by_userid] = true
        redirect_to  :action => 'index'
        return
      else
        flash[:notice] = "You must select a type"
        redirect_to :action => "files_for_specific_userid"
        return
      end
    end
  end

  def destroy
    load(params[:id])
    if  @batch.present?
      @batch.file_and_entries_delete
      @batch.delete
      flash[:notice] = 'The destruction of the physical files and all its entries and search records was successful'
    else
      flash[:notice] = 'The physical file does not exist'
    end
    redirect_to :back
  end

  def download
    file = PhysicalFile.id(params[:id]).first
    flash[:notice] = nil
    if file.present?
      my_file =  File.join(Rails.application.config.datafiles, file.userid,file.file_name) if params[:loc] == "FR2"
      my_file =  File.join(Rails.application.config.datafiles_changeset, file.userid,file.file_name) if params[:loc]  == "FR1"
      if File.file?(my_file)
        send_file( my_file, :filename => file.file_name,:x_sendfile=>true )
        flash[:notice] = "Downloaded"
      else
        flash[:notice] =  "There is a problem with the file you are attempting to download"
        redirect_to :action => :index
        return
      end
    else
      flash[:notice] =  "There is a problem with the file you are attempting to download. Contact a system administrator if you are concerned."
      redirect_to :action => :index
      return
    end
  end

  def files_for_specific_userid
    get_user_info_from_userid
    @batch = PhysicalFile.new
    @users = UseridDetail.get_userids_for_selection('all')
    @options = ["All files","Not processed","Processed but no file","Waiting to be processed"]
  end

  def file_not_processed
    @batches = PhysicalFile.uploaded_into_base.not_processed.all.order_by(base_uploaded_date: -1, userid: 1)
    @selection = 'all'
    @sorted_by = 'Not processed'
    session[:sorted_by] =  @sorted_by
    @number =  @batches.length
    @paginate = false
    @user = get_user
    session[:by_userid] = false
    session[:who] = @user
    @has_access = ((@user.person_role == "data_manager") || (@user.person_role == "system_administrator"))
    render  'index'
  end

  def get_counties_for_selection
    @counties = Array.new
    County.all.order_by(chapman_code: 1).each do |county|
      @counties << county.chapman_code
    end
  end

  def index
    if params[:page]
      session[:physical_index_page] = params[:page]
    end
    session[:sorted_by].nil? ?  @sorted_by = "All files by userid then batch name" : @sorted_by = session[:sorted_by]
    get_user_info_from_userid
    @has_access = ((@user.person_role == "data_manager") || (@user.person_role == "system_administrator"))
    case
    when @sorted_by ==  "All files by userid then batch name" && @has_access && !session[:by_userid]
      @batches = PhysicalFile.all.order_by(userid: 1,file_name: 1 ).page(params[:page]).per(1000)
      @number =  @batches.length
      @selection = 'all'
      @paginate = true
    when @sorted_by ==  "Not processed" && @has_access && !session[:by_userid]
      @batches = PhysicalFile.uploaded_into_base.not_processed.all.order_by(base_uploaded_date: -1, userid: 1).page(params[:page]).per(1000)
      @number =  @batches.length
      @selection = 'all'
      @paginate = false
    when   @sorted_by == 'All files' && @has_access && !session[:by_userid]
      @batches = PhysicalFile.all.order_by(userid: 1,base_uploaded_date: 1).page(params[:page]).per(1000)
      @number =  @batches.length
      @selection = 'all'
      @paginate = true
    when   @sorted_by == "Processed but no file" && @has_access && !session[:by_userid]
      @batches = PhysicalFile.processed.not_uploaded_into_base.all.order_by(userid: 1,file_processed_date: 1).page(params[:page]).per(1000)
      @number =  @batches.length
      @selection = 'all'
      @paginate = false
    when   @sorted_by == "Waiting to be processed" && @has_access && !session[:by_userid]
      @batches = PhysicalFile.waiting.all.order_by(waiting_date: -1)
      @number =  @batches.length
      @selection = 'all'
      @paginate = false
    when @sorted_by ==  "Not processed" && session[:who].present?
      @batches = PhysicalFile.userid(session[:who]).uploaded_into_base.not_processed.all.order_by(base_uploaded_date: -1, userid: 1).page(params[:page]).per(1000)
      @number =  @batches.length
      @selection = session[:who]
      @paginate = false
    when   @sorted_by == 'All files' && session[:who].present?
      @batches = PhysicalFile.userid(session[:who]).all.order_by(userid: 1,base_uploaded_date: 1).page(params[:page]).per(1000)
      @number =  @batches.length
      @selection = session[:who]
      @paginate = true
    when   @sorted_by == "Processed but no file" && session[:who].present?
      @batches = PhysicalFile.userid(session[:who]).processed.not_uploaded_into_base.all.order_by(userid: 1,file_processed_date: 1).page(params[:page]).per(1000)
      @number =  @batches.length
      @selection = session[:who]
      @paginate = false
    when   @sorted_by == "Waiting to be processed" && session[:who].present?
      @batches = PhysicalFile.userid(session[:who]).waiting.all.order_by(waiting_date: -1)
      @number =  @batches.length
      @selection = session[:who]
      @paginate = false
    end
    @nature = "all"
    respond_to do |format|
      format.html
      format.csv {send_data PhysicalFile.as_csv(@batches,@sorted_by,session[:who], session[:county]), filename: "physical_file.csv"}
    end
  end

  def load(batch)
    @batch = PhysicalFile.id(batch).first
  end

  def processed_but_no_file
    @sorted_by = 'Processed but no file'
    @selection = 'all'
    session[:by_userid] = false
    session[:sorted_by] =  @sorted_by
    @batches = PhysicalFile.processed.not_uploaded_into_base.order_by(userid: 1,file_processed_date: 1).all
    @number =  @batches.length
    @paginate = false
    render  'index'
  end

  def remove
    load(params[:id])
    if @batch.present?
      @batch.file_delete
      @batch.delete
      flash[:notice] = 'The file and physical files entry was removed'
    else
      flash[:notice] = 'The file does not exists'
    end
    redirect_to :back
  end

  def reprocess
    file = Freereg1CsvFile.find(params[:id])
    #we write a new copy of the file from current on-line contents
    ok_to_proceed = file.check_file
    if !ok_to_proceed[0]
      flash[:notice] =  "There is a problem with the file you are attempting to reproces #{ok_to_proceed[1]}. Contact a system administrator if you are concerned."
      redirect_to :back and return
    end
    file.backup_file
    @batch = PhysicalFile.where(:file_name => file.file_name, :userid => file.userid).first
    #add to processing queue and place in change
    success = @batch.add_file("reprocessing")
    if success[0]
      flash[:notice] = "The file #{@batch.file_name} for #{@batch.userid} has been submitted for processing" if success
    else
      flash[:notice] = "There was a problem with the reprocessing: #{success[1]} "
    end
    @batch.save
    redirect_to :back#freereg1_csv_files_path(:anchor => "#{file.id}")
    return
  end

  def select_action
    clean_session
    clean_session_for_county
    clean_session_for_syndicate
    get_user_info_from_userid
    @batches = PhysicalFile.new
    @options= UseridRole::PHYSICAL_FILES_OPTIONS
    @prompt = 'Select Action?'
  end

  def show
    #show an individual batch
    get_user_info_from_userid
    load(params[:id])
    if @batch.blank?
      flash[:notice] = 'File does not exist'
      redirect_to :back
    end
  end

  def sorted_by_base_uploaded_date(batches)
    batches = batches.sort {|a,b|
      cmp = a[:userid].downcase <=> b[:userid].downcase
      if 0==cmp #same userid, sort by upload date
        if a[:base_uploaded_date].nil?
          if b[:base_uploaded_date].nil?
            0
          else
            -1
          end
        elsif b[:base_uploaded_date].nil?
          1
        else
          a[:base_uploaded_date] <=> b[:base_uploaded_date]
        end
      else
        cmp
      end
    }
    #batches = Kaminari.paginate_array(batches).page(params[:page]).per(FreeregOptionsConstants::FILES_PER_PAGE)
    @paginate = false
    return batches
  end

  def submit_for_processing
    load(params[:id])
    if  @batch.present?
      success = @batch.add_file(params[:loc])
      flash[:notice] = success[1]
      redirect_to physical_files_path(:anchor => "#{@batch.id}", :page => "#{ session[:physical_index_page] }")
    else
      flash[:notice] = 'The file does not exist'
      redirect_to :back
    end
  end

  def waiting_to_be_processed
    @sorted_by = 'Waiting to be processed'
    session[:sorted_by] =  @sorted_by
    @selection = "all"
    session[:by_userid] = false
    session[:who] = @selection
    @batches = PhysicalFile.waiting.all.order_by(waiting_date: -1, userid: 1,)
    @number =  @batches.length
    @paginate = false
    @user = get_user
    @has_access = ((@user.person_role == "data_manager") || (@user.person_role == "system_administrator"))
    render  'index'
  end
end
