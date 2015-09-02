class CsvfilesController < ApplicationController

  require 'freereg_csv_update_processor'
  require 'digest/md5'


def new
  #get @userid
  get_user_info_from_userid
  #Lets create for the user and change later
  @csvfile  = Csvfile.new(:userid  => session[:userid])
  #get @people
  get_userids_and_transcribers
end

def create
  if params[:csvfile][:csvfile].blank?  
    flash[:notice] = 'You must select a file'
    redirect_to :back
    return 
  end
  p "create"
  p session
  p params
  get_user_info_from_userid
  @csvfile  = Csvfile.new(params[:csvfile])
  @csvfile.userid = session[:userid]   if params[:csvfile][:userid].nil?
  @csvfile.file_name = @csvfile.csvfile.identifier
  p @csvfile
  if params[:commit] = "Replace"
    #on a replace make sure its the same file_name
    if session[:file_name] == @csvfile.file_name
      #set up to allow the file save to occur in check_for_existing_place
      batch = PhysicalFile.where(userid: @csvfile.userid, file_name: @csvfile.file_name).first
      batch.update_attributes(:base => true,:file_processed => false)
    else
      flash[:notice] = 'The file you are replacing must have the same name'  
      session.delete(:file_name)
      redirect_to :back
      return 
    end
    session.delete(:file_name) 
  end
  #lets check for existing file, save if required
  proceed = @csvfile.check_for_existing_unprocessed_file 
  @csvfile.save if proceed
  if @csvfile.errors.any? || !proceed
    flash[:notice] = 'The upload of the file was unsuccessful, please review, correct and resubmit'
    get_userids_and_transcribers
    redirect_to :back
    return 
  end #errors
  @processing_time = @csvfile.save_and_estimate_time
  flash[:notice] = 'The upload of the file was successful' 
  render 'process' 
end #method

def edit
#code to move existing file to attic
 get_user_info_from_userid
 @file = Freereg1CsvFile.find(params[:id])
 if @file.locked_by_transcriber == 'true' ||  @file.locked_by_coordinator == 'true'
    flash[:notice] = 'The replacement of the file is not permitted as it has been locked due to on-line changes; download the updated copy and remove the lock' 
    redirect_to :back 
    return
 end
 @person = @file.userid
 @file_name = @file.file_name 
 @csvfile  = Csvfile.new(:userid  => @person, :file_name => @file_name)
 session[:file_name] =  @file_name 
 get_userids_and_transcribers
end
 
def update
  @user = UseridDetail.where(:userid => session[:userid]).first
  if params[:commit] == 'Process'
    @csvfile = Csvfile.find(params[:id])
    range = File.join(@csvfile.userid ,@csvfile.file_name)
    case
    when params[:csvfile][:process]  == "Just check for errors"
     pid1 = Kernel.spawn("rake build:freereg_update[#{range},\"no_search_records\",\"change\"]") 
     flash[:notice] =  "The csv file #{ @csvfile.file_name} is being checked. You will receive an email when it has been completed."  
    when params[:csvfile][:process]  == "Process tonight" 
      batch = PhysicalFile.where(:userid => @csvfile.userid, :file_name => @csvfile.file_name).first
      batch.add_file("change")
      flash[:notice] =  "The file has been placed in the queue for overnight processing"
    when params[:csvfile][:process]  == "As soon as you can"
      pid1 = Kernel.spawn("rake build:freereg_update[#{range},\"search_records\",\"change\"]") 
      flash[:notice] =  "The csv file #{ @csvfile.file_name} is being processed into the database. You will receive an email when it has been completed."
    else
    end #case
    @csvfile.delete
    if session[:my_own]
      redirect_to my_own_freereg1_csv_file_path
      return
    end #session
    redirect_to freereg1_csv_files_path( :page => "#{session[:files_index_page]}")
    return 
  end  #commit


end

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

def get_userids_and_transcribers
 syndicate = @user.syndicate
 syndicate = session[:syndicate] unless session[:syndicate].nil?
 @people =Array.new  
 @people <<  @user.userid
 case
 when @user.person_role == 'system_administrator' ||  @user.person_role == 'volunteer_coordinator' ||  @user.person_role == 'data_manager'
  @userids = UseridDetail.all.order_by(userid_lower_case: 1)
 when  @user.person_role == 'country_coordinator' || @user.person_role == 'county_coordinator'  || @user.person_role == 'syndicate_coordinator' 
  @userids = UseridDetail.syndicate(syndicate).all.order_by(userid_lower_case: 1) 
 else
  @userids = @user
 end #end case
  unless session[:my_own] 
    @userids.each do |ids|
      @people << ids.userid
    end
  end
end

def download
 @role = session[:role]
 @freereg1_csv_file = Freereg1CsvFile.find(params[:id])
 @freereg1_csv_file.backup_file
 my_file =  File.join(Rails.application.config.datafiles, @freereg1_csv_file.userid,@freereg1_csv_file.file_name)
 send_file( my_file, :filename => @freereg1_csv_file.file_name)
 @freereg1_csv_file.update_attribute(:digest, Digest::MD5.file(my_file).hexdigest)
end

end
