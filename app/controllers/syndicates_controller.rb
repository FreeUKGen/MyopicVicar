class SyndicatesController < ApplicationController


    def index
        if session[:userid].nil? 
          redirect_to '/', notice: "You are not authorised to use these facilities"
      end
      get_user_info_from_userid
      @syndicates = Syndicate.all.order_by(syndicate_code: 1)

  end

  def new
    get_user_info_from_userid
    @syndicate = Syndicate.new
    get_userids_and_transcribers
end

def edit
    load(params[:id])
    get_userids_and_transcribers
end

def create
    @syndicate = Syndicate.new(params[:syndicate])
    @syndicate.save
    if @syndicate.errors.any?

       flash[:notice] = "The addition of the Syndicate was unsuccessful"
       render :action => 'edit'
       return
   else
    flash[:notice] = "The addition of the Syndicate was successful"
	 #Syndicate.change_userid_fields(params)
    redirect_to syndicates_path
end
end

def update
  load(params[:id])
  my_params = params[:syndicate]
  my_params = @syndicate.update_fields_before_applying(my_params) 
  @syndicate.update_attributes(my_params)
    if @syndicate.errors.any?
       get_userids_and_transcribers
       flash[:notice] = "The change to the Syndicate was unsuccessful"
       render :action => 'edit'
       return
   else
    @syndicate.update_attributes(:changing_name => false) if @syndicate.changing_name
    flash[:notice] = "The change to the Syndicate was successful"
    redirect_to syndicates_path
end

end

def show
    load(params[:id])
    person = UseridDetail.where(:userid => @syndicate.syndicate_coordinator).first
    @person = person.person_forename + ' ' + person.person_surname unless person.nil? 
    person = UseridDetail.where(:userid => @syndicate.previous_syndicate_coordinator).first
    @previous_person = person.person_forename + ' ' + person.person_surname unless person.nil? 
end
def selection
  get_user_info_from_userid
  session[:syndicate] = 'all' if @user.person_role == 'system_administrator'
  case 
    when params[:synd] == 'Browse syndicates'
      @syndicates = Syndicate.all.order_by(syndicate_code: 1)
      render "index"
      return
    when params[:synd] == "Create syndicate"
      redirect_to :action => 'new' 
      return
    when params[:synd] == "Show specific syndicate"
      syndicates = Syndicate.all.order_by(syndicate_code: 1)
      @syndicates = Array.new
      syndicates.each do |synd|
        @syndicates << synd.syndicate_code
      end
      @location = 'location.href= "select?action=show&synd=" + this.value'
    when params[:synd] == "Edit specific syndicate"
      syndicates = Syndicate.all.order_by(syndicate_code: 1)
      @syndicates = Array.new
      syndicates.each do |synd|
        @syndicates << synd.syndicate_code
      end
      @location = 'location.href= "select?action=edit&synd=" + this.value'
    else
      flash[:notice] = 'Invalid option'
      redirect_to :back
      return   
    end
      @prompt = 'Select syndicate'
      @syndicate = session[:syndicate]
end
def select
  get_user_info_from_userid
  case 
  when !params[:synd].nil? 
    if params[:synd] == ""
       flash[:notice] = 'Blank cannot be selected'
       redirect_to :back
       return
    else
      syndicate = Syndicate.where(:syndicate_code => params[:synd]).first
      if params[:action] == "show"
        redirect_to syndicate_path(syndicate)
        return
      else
        redirect_to edit_syndicate_path(syndicate)
        return
      end
    end
  else
    flash[:notice] = 'Invalid option'
    redirect_to :back
    return   
  end
end 

def load(id)
    @first_name = session[:first_name]
    @syndicate = Syndicate.find(id)
    get_user_info_from_userid
end

def get_userids_and_transcribers
    @user = UseridDetail.where(:userid => session[:userid]).first
    case
    when @user.person_role == 'system_administrator' ||  @user.person_role == 'volunteer_coordinator'
        @userids = UseridDetail.all.order_by(userid_lower_case: 1)
    when  @user.person_role == 'country_cordinator'
         @userids = UseridDetail.where(:syndicate => @user.syndicate ).all.order_by(userid_lower_case: 1) # need to add ability for more than one county
     when  @user.person_role == 'county_coordinator'  
         @userids = UseridDetail.where(:syndicate => @user.syndicate ).all.order_by(userid_lower_case: 1) # need to add ability for more than one syndicate  
     when  @user.person_role == 'sydicate_coordinator'  
         @userids = UseridDetail.where(:syndicate => @user.syndicate ).all.order_by(userid_lower_case: 1) # need to add ability for more than one syndicate  
     else
          @userids = @user
     end #end case
     @people =Array.new
     @userids.each do |ids|
        @people << ids.userid
       end
end

def destroy
    load(params[:id])
     if UseridDetail.where(:syndicate => @syndicate.syndicate_code).exists?
      flash[:notice] = 'The deletion of the Syndicate cannot proceed as it still has members.'
      redirect_to syndicate_path(@syndicate)
     else
     @syndicate.destroy
     flash[:notice] = 'The deletion of the Register was successful'
     redirect_to syndicates_path
     end
end
end

