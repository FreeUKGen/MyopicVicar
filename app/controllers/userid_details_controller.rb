class UseridDetailsController < ApplicationController
 require 'userid_role'

	def index
     if session[:userid].nil?
      redirect_to '/', notice: "You are not authorised to use these facilities"
    end
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
    session[:type] = "manager"
    session[:my_own] = "no"
      users = UseridDetail.where(:syndicate => session[:syndicate]).all.order_by(userid_lower_case: 1) 
      @role = session[:role]
      @userids = Array.new
           users.each do |user|
              @userids << user
           end
      
 	end #end method
 


  def new
    session[:type] = "add"
    @userid = UseridDetail.new
    @first_name = session[:first_name]
     @user = UseridDetail.where(:userid => session[:userid]).first
    synd = Syndicate.all.order_by(syndicate_code: 1)
     @role = session[:role]
    @syndicates = Array.new
    synd.each do |syn|
        @syndicates << syn.syndicate_code
     end
   
    
  end
   
  def show
    load(params[:id])
    
   end

  def my_own
    @userid = session[:userid]
    @first_name = session[:first_name]
    @userid = UseridDetail.where(:userid => session[:userid]).first
    session[:my_own] = 'my_own'
    @user = @userid
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
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
     @userid = UseridDetail.new(params[:userid_detail])
     @userid.sign_up_date = DateTime.now
     @userid.syndicate =  session[:syndicate]  unless @user.person_role == 'system_administrator'
     @userid.person_role = 'transcriber' unless @user.person_role == 'system_administrator'
     @userid.save
   
      if @userid.errors.any?
  
   
     flash[:notice] = 'The addition of the person was unsuccessful'
     render :action => 'new'
     return
     else
     flash[:notice] = 'The addition of the person was successful'
      if @user.person_role == 'system_administrator'
        @userids = Array.new
         profiles = UseridDetail.all.order_by(userid_lower_case: 1)
    
          profiles.each do |profile|
            @userids << profile
          end
          render :action => 'index'
          return
      else
      redirect_to userid_details_path(:anchor => "#{ @userid.id}")
      end
    end
  end

  def update
    load(params[:id])
  	if session[:type] == "disable" 
  	 params[:userid_detail][:disabled_date]  = DateTime.now if  @userid.disabled_date.nil? 
     params[:userid_detail][:active]  = false  
    end
    params[:userid_detail][:person_role] = params[:userid_detail][:person_role] unless params[:userid_detail][:person_role].nil?
   
    @userid.update_attributes!(params[:userid_detail])
    if @userid.errors.any?
     
      flash[:notice] = 'The update of the details were unsuccessful'
      render :action => 'edit'
      return
    else
      flash[:notice] = 'The update of the details were successful'
      if session[:my_own] == "my_own"
       render :action => 'show'
       return
      else
          if @user.person_role == 'system_administrator'
            @userids = Array.new
              profiles = UseridDetail.all.order_by(userid_lower_case: 1)
    
                profiles.each do |profile|
                  @userids << profile
                end
           render :action => 'index'
           return
      else
      redirect_to userid_details_path(:anchor => "#{ @userid.id}")
      end
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
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
    @userid = UseridDetail.find(userid_id)
    session[:userid_id] = userid_id
    @role = session[:role]
  end
end

