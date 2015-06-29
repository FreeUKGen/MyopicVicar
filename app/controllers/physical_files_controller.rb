class PhysicalFilesController < InheritedResources::Base

def index
  @sorted_by = session[:sorted_by] unless session[:sorted_by].nil?
  get_user_info_from_userid
  @batches = PhysicalFile.all.order_by(userid: 1,batch_name: 1).page(params[:page]) 
end 

def show
  #show an individual batch
  get_user_info_from_userid
  p params
  load(params[:id])  
end

def for_userid
  @batches = PhysicalFile.by_userid(id)
  render 'index'
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
def not_processed
  get_user_info_from_userid
  @sorted_by = '(not processed)'
  session[:sorted_by] = @sorted_by
  @batches = PhysicalFile.not_processed.all.page(params[:page])
  render 'index'
end
def processed_but_not_in_base
  get_user_info_from_userid
  @sorted_by = '(processed but not in the base folder)'
  session[:sorted_by] = @sorted_by
  @batches = PhysicalFile.processed.not_loaded_into_base.all.page(params[:page])
  render 'index'
end
def processed_but_not_in_change
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
  end
  def userid
    @user = params[:params]
    @sorted_by = session[:sorted_by] + "( for userid #{@user} )"
    case 
    when session[:sorted_by] == 'all files'
      @batches = PhysicalFile.userid(params[:params]).all.page(params[:page])
    when session[:sorted_by] == 'not processed'
      @batches = PhysicalFile.userid(params[:params]).not_processed.all.page(params[:page]) 
    end
    render 'index' 
  end

end