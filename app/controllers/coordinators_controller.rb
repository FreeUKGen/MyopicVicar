class CoordinatorsController < ApplicationController
   require 'record_type'
   require 'chapman_code'
def index
 unless params[:commit] == "Select"
   reset_session
   session[:userid] = "RobynPerrim" # This has to be read from somewhere
   @syndicates = Syndicate.where(:syndicate_coordinator => session[:userid]).all
   @first_name = UseridDetail.where(:userid => session[:userid]).first.person_forename
   session[:first_name] =  @first_name
   @number_of_syndicates = @syndicates.length
   @coordinators = Coordinator.new

   p @syndicates
   p @number_of_syndicates
    if @number_of_syndicates == 1 
    @syndicates = Syndicate.where(:syndicate_coordinator => session[:userid]).first
     session[:chapman_code] = @syndicates.chapman_code
     @county = ChapmanCode.has_key(@syndicates.chapman_code)
     session[:county] = @county
     session[:muliple] = false
    else
   	 session[:muliple] = true
   	  synd = Array.new
   	  @syndicates.each do |syn|
   	  	synd << syn.syndicate_code
   	  end
   	  @syndicates = synd
    end #end if
  else
    @first_name = session[:first_name]
    @county	= session[:county]
  end #end unless
 end #end index


 def create
  if params[:commit] == "Select"
  	session[:chapman_code] = params[:coordinator][:chapman_code]
    @county = ChapmanCode.has_key(session[:chapman_code])

    p "should be #{county}"
    session[:county] = @county
    redirect_to coordinators_path(params)
  else
    redirect_to :action => :new
  end #if
  end # create
end
