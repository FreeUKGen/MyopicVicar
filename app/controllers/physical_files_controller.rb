class PhysicalFilesController < InheritedResources::Base

  def index
    if params[:page]
      session[:physical_index_page] = params[:page]
    end
    @sorted_by = session[:sorted_by] unless session[:sorted_by].nil?
    get_user_info_from_userid
    case 
    when session[:sorted_by] == '(Change not processed)'
      @batches = PhysicalFile.uploaded_into_change.not_processed.all.page(params[:page])
    when session[:sorted_by] == '(Base not processed)'
      @batches = PhysicalFile.uploaded_into_base.not_processed.all.page(params[:page])
    when session[:sorted_by] == '(All not processed)'
      @batches = PhysicalFile.not_processed.all.page(params[:page])  
    when session[:sorted_by] == '(processed but not in the base folder)'
      @batches = PhysicalFile.processed.not_uploaded_into_base.all.page(params[:page])
    when session[:sorted_by] == '(processed but no files)'
      @batches = PhysicalFile.processed.not_uploaded_into_change.not_loaded_into_base.all.page(params[:page])
    when session[:sorted_by] == '(processed but not in the change folder)'
      @batches = PhysicalFile.processed.not_uploaded_into_change.all.page(params[:page])
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
    get_user_info_from_userid
    @batches = PhysicalFile.new
    @options= UseridRole::PHYSICAL_FILES_OPTIONS
    @prompt = 'Select Action?'
  end


  def load(batch)
    @batch = PhysicalFile.find(batch)
  end
  def change_not_processed
    if params[:page]
      session[:files_index_page] = params[:page]
    end
    get_user_info_from_userid
    @sorted_by = '(Change not processed)'
    session[:sorted_by] = @sorted_by
    @batches = PhysicalFile.uploaded_into_change.not_processed.all.page(params[:page])    
    render 'index'
  end
  def base_not_processed
    if params[:page]
      session[:files_index_page] = params[:page]
    end
    get_user_info_from_userid
    @sorted_by = '(Base not processed)'
    session[:sorted_by] = @sorted_by
    @batches = PhysicalFile.uploaded_into_base.not_processed.all.page(params[:page])    
    render 'index'
  end
  def all_not_processed
    if params[:page]
      session[:files_index_page] = params[:page]
    end
    get_user_info_from_userid
    @sorted_by = '(All not processed)'
    session[:sorted_by] = @sorted_by
    @batches = PhysicalFile.not_processed.all.page(params[:page])    
    render 'index'
  end
  def processed_but_not_in_base
    if params[:page]
    session[:files_index_page] = params[:page]
    end
    get_user_info_from_userid
    @sorted_by = '(processed but not in the base folder)'
    session[:sorted_by] = @sorted_by
    @batches = PhysicalFile.processed.not_uploaded_into_base.all.page(params[:page])
    render 'index'
  end
  def processed_but_no_file
    if params[:page]
    session[:files_index_page] = params[:page]
    end
    get_user_info_from_userid
    @sorted_by = '(processed but no files)'
    session[:sorted_by] = @sorted_by
    @batches = PhysicalFile.processed.not_uploaded_into_change.not_uploaded_into_base.all.page(params[:page])
    render 'index'
    
  end
  def processed_but_not_in_change
    if params[:page]
    session[:files_index_page] = params[:page]
    end
    get_user_info_from_userid
    @sorted_by = '(processed but not in the change folder)'
    session[:sorted_by] = @sorted_by
    @batches = PhysicalFile.processed.not_uploaded_into_change.all.page(params[:page])
    render 'index'
  end
  def files_for_specific_userid
    get_user_info_from_userid
    @batch = PhysicalFile.new
    @userids = Array.new
    UseridDetail.all.order_by(userid_lower_case: 1).each do |user|
     @userids << user.userid
    end
    @options = @userids
    session[:sorted_by] = 'all files'
    @location = 'location.href= "/physical_files/userid?params=" + this.value'
    @prompt = 'Select Userid'
    render '_form_for_selection'
  end
  def files_for_specific_userid_not_processed
    get_user_info_from_userid
    @batch = PhysicalFile.new
    @userids = Array.new
    UseridDetail.all.order_by(userid_lower_case: 1).each do |user|
     @userids << user.userid
    end
    @options = @userids
    session[:sorted_by] = 'not processed'
    @location = 'location.href= "/physical_files/userid?params=" + this.value'
    @prompt = 'Select Userid'
    render '_form_for_selection'
    return
  end
  def userid
    @user = params[:params]  
    @sorted_by = session[:sorted_by] + ( " for #{@user}")  
    case 
    when session[:sorted_by] == 'all files'
      @batches = PhysicalFile.where(:userid => @user).all
    when session[:sorted_by] == 'not processed'
      @batches = PhysicalFile.userid(@user).not_processed.all
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
      @batch = PhysicalFile.new(:file_name => file.file_name, :userid => file.userid, :change_uploaded_date => Time.now, :change => true)
      #add to processing queue and place in change
      success = @batch.add_file("reprocessing")
      flash[:notice] = "The file #{@batch.file_name} for #{@batch.userid} has been added to the overnight queue for processing" if success
      @batch.save
      redirect_to freereg1_csv_files_path(:anchor => "#{file.id}", :page => "#{session[:files_index_page]}")
    end

end