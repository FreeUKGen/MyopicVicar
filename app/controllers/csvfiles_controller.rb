class CsvfilesController < InheritedResources::Base
def index
end
 
def new
 
@user = session[:user]
@first_name = session[:first_name]	
@userid = session[:userid]	
@csvfile  = Csvfile.new(:userid  => session[:userid])
get_userids_and_transcribers

end

def edit
 
  #code to move existing file to attic
  @user = session[:user]
  @first_name = session[:first_name]  
  @userid = session[:userid]  
  @csvfile  = Csvfile.new(:userid  => session[:userid])
  @csvfile.file_name = Freereg1CsvFile.find(params[:id]).file_name
  session[:freereg]  = params[:id]
  @file = @csvfile.file_name 
  get_userids_and_transcribers
end

def create
 
  @csvfile  = Csvfile.new(params[:csvfile])
  @csvfile[:freereg1_csv_file_id] = session[:freereg] 
  session[:freereg]  = nil
  @csvfile[:userid] = session[:userid]
  @csvfile[:userid] = params[:csvfile][:userid] unless params[:csvfile][:userid].nil?
  @csvfile.file_name = @csvfile.csvfile.identifier
    if params[:commit] == 'Replace'
      @csvfile.save_to_attic
    end
    if @csvfile.save!

       place  = @csvfile.file_name
       range = File.join(@csvfile[:userid] ,@csvfile.file_name)

          unless params[:csvfile][:process] == 'Scheduled'
            start = Time.now
            pid1 = Kernel.spawn("rake build:process_freereg1_csv[recreate,no,#{range}]") 
             Process.waitall if params[:csvfile][:process]  == 'Now'
            endtime = Time.now - start
           end
      
      @csvfile.delete

          if session[:my_own] == 'my_own'
            redirect_to my_own_freereg1_csv_file_path(:anchor =>"#{session[:freereg1_csv_file_id]}"), notice: "The csv file #{place} is being/has been uploaded."
          return
         end
          redirect_to freereg1_csv_files_path(:anchor =>"#{session[:freereg1_csv_file_id]}"), notice: "The csv file #{place} is being/has been uploaded."
         else
            # problem situation
            render "new"
        end
end


def delete
 
 @csvfile  = Csvfile.new(:userid  => session[:userid])
 freefile = Freereg1CsvFile.find(params[:id])
 @csvfile.file_name = freefile.file_name
 @csvfile.freereg1_csv_file_id = freefile._id
 @csvfile.save_to_attic
 @csvfile.delete
 redirect_to my_own_freereg1_csv_file_path(:anchor =>"#{session[:freereg1_csv_file_id]}"),notice: "The csv file #{freefile.file_name} has been deleted."
end

def get_userids_and_transcribers
@user = session[:user]
  case
    when @user.person_role == 'system_administrator' ||  @user.person_role == 'volunteer_coordinator'
        @userids = UseridDetail.all.order_by(userid_lower_case: 1)
    when  @user.person_role == 'country_cordinator'
        @userids = UseridDetail.where(:syndicate => @user.syndicate ).all.order_by(userid_lower_case: 1) # need to add ability for more than one county
    when  @user.person_role == 'county_coordinator'  
        @userids = UseridDetail.where(:syndicate => @user.syndicate ).all.order_by(userid_lower_case: 1) # need to add ability for more than one syndicate  
    when  @user.person_role == 'sydicate_coordinator'  
        @userids = UseridDetail.where(:syndicate => @user.syndicate ).all.order_by(userid_lower_case: 1) # need to add ability for more than one syndicate  
    
    end #end case
    @people =Array.new
    @userids.each do |ids|
    @people << ids.userid
    end
  
end

def download
  @freereg1_csv_file = Freereg1CsvFile.find(params[:id])
  my_file =  File.join(Rails.application.config.datafiles, @freereg1_csv_file.userid,@freereg1_csv_file.file_name)
  send_file( my_file, :filename => @freereg1_csv_file.file_name)
 
end

end
