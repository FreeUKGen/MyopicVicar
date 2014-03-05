class UseridDetailsController < ApplicationController
 require 'userid_role'

	def index
    @userid = session[:userid]
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
    session[:user] = @user
     session[:type] = "manager"
     session[:my_own] = "no"
    case
    when @user.person_role == 'system_administrator' ||  @user.person_role == 'volunteer_coordinator'
        @userids = UseridDetail.all.order_by(userid_lower_case: 1)

    when @user.person_role == "syndicate_coordinator" || (@user.person_role == 'county_coordinator' && @user.syndicate_groups.length > 0) || (@user.person_role == 'country_coordinator' && @user.syndicate_groups.length > 0)
         @userids = Array.new
         syndicates = Syndicate.where(:syndicate_coordinator => @user.userid).all.order_by(syndicate_code: 1) 
         syndicates.each do |synd|
           users = UseridDetail.where(:syndicate => synd.syndicate_code).all.order_by(userid: 1) 
           users.each do |user|
           @userids << user
         end
       end
    end #end case

 	end #end method

  def new
    session[:type] = "add"
    @userid = UseridDetail.new
    @first_name = session[:first_name]
    synd = Syndicate.all.order_by(syndicate_code: 1)
    @syndicates = Array.new
    synd.each do |syn|
        @syndicates << syn.syndicate_code
     end
    
  end
   
  def show
    load(params[:id])
  
   
  end
  def my_own
    @user = session[:user]
    @first_name = session[:first_name]
    session[:my_own] = "my-own"
   
    @userid = UseridDetail.where(:userid => @user.userid ).first
    #redirect_to userid_detail_path(@userids)
    render :action => 'show'

  end

  def edit
    session[:type] = "edit"
   
     load(params[:id])
     synd = Syndicate.all.order_by(syndicate_code: 1)
     @syndicates = Array.new
     synd.each do |syn|
       @syndicates << syn.syndicate_code
     end

  end

  def create
    p "update userid"
    p session
     @userid = UseridDetail.new(params[:userid_detail])
     @userid.sign_up_date = DateTime.now
     @userid.save
   
      if @userid.errors.any?
     session[:errors] = @userid.errors.messages
     flash[:notice] = 'The addition of the person was unsuccsessful'
     render :action => 'new'
     return
     else
     flash[:notice] = 'The addition of the person was succsessful'
      redirect_to userid_details_path(:anchor => "#{ @userid.id}")
    end
  end

  def update
    load(params[:id])
  	if session[:type] == "disable" 
  	 params[:userid_detail][:disabled_date]  = DateTime.now if  @userid.disabled_date.nil? || @userid.disabled_date.empty?
     params[:userid_detail][:active]  = false  
    end
    params[:userid_detail][:person_role] = UseridRole.name_from_code(params[:userid_detail][:person_role]).to_s unless params[:userid_detail][:person_role].nil?
   
    @userid.update_attributes!(params[:userid_detail])
    if @userid.errors.any?
      session[:errors] = @userid.errors.messages
      flash[:notice] = 'The update of the details were unsuccsessful'
      render :action => 'edit'
      return
    else
      flash[:notice] = 'The update of the details were succsessful'
      if session[:my_own] == "my-own"
       render :action => 'show'
       return
      else
         redirect_to userid_details_path(:anchor => "#{ @userid.id}")
       end
     
     end
end

def destroy
end

 def disable
  load(params[:id])
 	session[:type] = "disable"
 end

  def load(userid_id)
   @userid = UseridDetail.find(userid_id)
   session[:userid_id] = userid_id
   @first_name = session[:first_name]
  end
end

