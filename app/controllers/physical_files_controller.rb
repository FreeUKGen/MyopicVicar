class PhysicalFilesController < InheritedResources::Base

  def index
    if params[:page]
      session[:physical_index_page] = params[:page]
    end
    @sorted_by = "(All files by userid then batch name)"
    @sorted_by = session[:sorted_by] unless session[:sorted_by].nil?
    get_user_info_from_userid
    p  @sorted_by
    case 
    when session[:sorted_by] == '(File not processed)'
    @batches = PhysicalFile.not_processed.all.order_by(base_uploaded_date: 1).page(params[:page])    
    when session[:sorted_by] == '(Processed but no file)'
      @batches = PhysicalFile.processed.not_uploaded_into_base.all.page(params[:page])
    when session[:sorted_by] == 'all files'
      @batches = PhysicalFile.userid(@user).all.order_by(base_uploaded_date: 1).page(params[:page])
    when session[:sorted_by] == 'processed but no file'
      @batches = PhysicalFile.userid(@user).processed.not_uploaded_into_base.all.order_by(file_processed_date: 1).page(params[:page])  
    when session[:sorted_by] == 'files_not processed'
      @batches = PhysicalFile.userid(@user).not_processed.all.order_by(base_uploaded_date: 1).page(params[:page])
    else
      @batches = PhysicalFile.all.order_by(userid: 1,batch_name: 1).page(params[:page])
    end
    session[:paginate] = true
  end 

  def show
    #show an individual batch
    get_user_info_from_userid
    load(params[:id])  
  end

  
  def select_action
    session.delete(:sorted_by)
    get_user_info_from_userid
    @batches = PhysicalFile.new
    @options= UseridRole::PHYSICAL_FILES_OPTIONS
    @prompt = 'Select Action?'
  end


  def load(batch)
    @batch = PhysicalFile.find(batch)
  end
  
  def file_not_processed
    if params[:page]
      session[:files_index_page] = params[:page]
    end
    get_user_info_from_userid
    @sorted_by = '(File not processed)'
    session[:sorted_by] = @sorted_by
    @batches = PhysicalFile.not_processed.all.order_by(base_uploaded_date: 1).page(params[:page])    
    render 'index'
  end
  
  def processed_but_no_file
    if params[:page]
    session[:files_index_page] = params[:page]
    end
    get_user_info_from_userid
    @sorted_by = '(Processed but no file)'
    session[:sorted_by] = @sorted_by
    @batches = PhysicalFile.processed.not_uploaded_into_base.all.order_by(file_processed_date: 1).page(params[:page])
    render 'index'
    
  end
  
  def files_for_specific_userid
    get_user_info_from_userid
    @batch = PhysicalFile.new
    @options = UseridDetail.get_userids_for_selection('all')
    session[:sorted_by] = 'all files'
    @location = 'location.href= "/physical_files/userid?params=" + this.value'
    @prompt = 'Select Userid'
    render '_form_for_selection'
  end
   
  def processed_but_no_file_for_specific_userid
    get_user_info_from_userid
    @batch = PhysicalFile.new
    @options = UseridDetail.get_userids_for_selection('all')
    session[:sorted_by] = 'processed but no file'
    @location = 'location.href= "/physical_files/userid?params=" + this.value'
    @prompt = 'Select Userid'
    render '_form_for_selection'
  end
  def files_not_processed_specific_userid
    get_user_info_from_userid
    @batch = PhysicalFile.new
    @options = UseridDetail.get_userids_for_selection('all')
    session[:sorted_by] = 'files_not_processed'
    @location = 'location.href= "/physical_files/userid?params=" + this.value'
    @prompt = 'Select Userid'
    render '_form_for_selection'
  end
  
  def userid
    if params[:page]
      session[:physical_index_page] = params[:page]
    end
    @user = params[:params]  
    @sorted_by = session[:sorted_by] + ( " for #{@user}")  
    case 
    when session[:sorted_by] == 'all files'
      #@batches = PhysicalFile.where(:userid => @user).all.order_by(base_uploaded_date: 1).page(params[:page])
      @batches = PhysicalFile.userid(@user).all.order_by(base_uploaded_date: 1).page(params[:page])
    when session[:sorted_by] == 'processed but no file'
      @batches = PhysicalFile.userid(@user).processed.not_uploaded_into_base.all.order_by(file_processed_date: 1).page(params[:page])  
    when session[:sorted_by] == 'files_not_processed'
      @batches = PhysicalFile.userid(@user).not_processed.all.order_by(base_uploaded_date: 1).page(params[:page])
    end
    session[:paginate] = false
    render 'index' 
    return 
  end

  def submit_for_processing
    load(params[:id])
    success = @batch.add_file(params[:loc])
    flash[:notice] = "The file #{@batch.file_name} for #{@batch.userid} has been added to the overnight queue for processing" if success
    @batch.update_attributes(:change_uploaded_date => Time.now, :change => true)
    redirect_to physical_files_path(:anchor => "#{@batch.id}", :page => "#{ session[:physical_index_page] }")   
  end
  def reprocess
      file = Freereg1CsvFile.find(params[:id])
      #we write a new copy of the file from current on-line contents
      file.backup_file
      @batch = PhysicalFile.where(:file_name => file.file_name, :userid => file.userid).first
      #add to processing queue and place in change
      success = @batch.add_file("reprocessing")
      flash[:notice] = "The file #{@batch.file_name} for #{@batch.userid} has been added to the overnight queue for processing" if success
      @batch.save
      redirect_to :back#freereg1_csv_files_path(:anchor => "#{file.id}", :page => "#{session[:files_index_page]}")
    end

end