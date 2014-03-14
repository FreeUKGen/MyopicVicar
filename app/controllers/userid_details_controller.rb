class UseridDetailsController < ApplicationController
 require 'userid_role'

	def index
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
    session[:type] = "manager"
    session[:my_own] = "no"

     users = UseridDetail.where(:syndicate => session[:syndicate]).all.order_by(userid_lower_case: 1) 
     
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
    session[:my_own] = 'my-own'
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
     @userid = UseridDetail.new(params[:userid_detail])
     @userid.sign_up_date = DateTime.now
     @userid.syndicate =  session[:syndicate]
     @userid.person_role = 'transcriber'
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
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
    @userid = UseridDetail.find(userid_id)
    session[:userid_id] = userid_id
  
  end
end

