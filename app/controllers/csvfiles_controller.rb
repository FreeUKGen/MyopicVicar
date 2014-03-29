class CsvfilesController < InheritedResources::Base
def index
end
 
def new
 
 @user = UseridDetail.where(:userid => session[:userid]).first
@first_name = session[:first_name]	
@userid = session[:userid]	
@csvfile  = Csvfile.new(:userid  => session[:userid])
get_userids_and_transcribers

end

def edit
 
  #code to move existing file to attic
  @user = UseridDetail.where(:userid => session[:userid]).first
  @first_name = session[:first_name]  
  @userid = session[:userid]  
  @csvfile  = Csvfile.new(:userid  => session[:userid])
  @csvfile.file_name = Freereg1CsvFile.find(params[:id]).file_name
  session[:freereg]  = params[:id]
  @file = @csvfile.file_name 

  get_userids_and_transcribers
end

def update
  if params[:commit] == 'Process'
     @csvfile = Csvfile.find(session[:csvfile])
    place  = @csvfile.file_name
    range = File.join(@csvfile[:userid] ,@csvfile.file_name)
          unless params[:csvfile][:process] == 'Scheduled'
            start = Time.now
            pid1 = Kernel.spawn("rake build:process_freereg1_csv[recreate,no,#{range}]") 
             Process.waitall if params[:csvfile][:process]  == 'Now'
            endtime = Time.now - start
          end #unless
     @csvfile.delete
   flash[:notice] =  "The csv file #{place}  has been uploaded if you 'Waited' or will soon be if you did not."
     case
      when session[:role] == 'syndicate'
         if session[:my_own] == 'my_own'
            redirect_to my_own_freereg1_csv_file_path(:anchor =>"#{session[:freereg1_csv_file_id]}")
          return
         end #my_own
          redirect_to freereg1_csv_files_path(:anchor =>"#{session[:freereg1_csv_file_id]}")
         return
     when session[:role] == 'counties'
         redirect_to places_path
         return
     else
       redirect_to :back
     end #case
  end  #commit

end

def create
  @csvfile  = Csvfile.new(params[:csvfile])
  @csvfile[:freereg1_csv_file_id] = session[:freereg] 
  session[:freereg]  = nil
  session[:csvfile] = @csvfile._id
  @csvfile[:userid] = session[:userid]
  @csvfile[:userid] = params[:csvfile][:userid] unless params[:csvfile][:userid].nil?
  @csvfile.file_name = @csvfile.csvfile.identifier
  
  if params[:commit] == 'Replace'
      @csvfile.save_to_attic
    end #end if
  unless File.exists?("#{File.join(Rails.application.config.datafiles,@csvfile[:userid] ,@csvfile.file_name)}")
    @csvfile.save

  unless @csvfile.errors.any?
     @user = UseridDetail.where(:userid => session[:userid]).first
     flash[:notice] = 'The upload of the file was succsessful'
     place = File.join(Rails.application.config.datafiles,@csvfile[:userid] ,@csvfile.file_name)
      size = (File.size("#{place}"))
      unit = 0.001
     @processing_time = 60 + (size.to_i*unit) 
     render 'process' 
     return
  end #end unless
   flash[:notice] = 'The upload of the file was unsuccsessful'
     redirect_to 'new'
     return
  end #uless exists
    flash[:notice] = 'The file already exists; if you wish to replace it use the Replace option'
          
         if session[:my_own] == 'my_own'
            redirect_to my_own_freereg1_csv_file_path(:anchor =>"#{session[:freereg1_csv_file_id]}")
          return
         end
          redirect_to freereg1_csv_files_path(:anchor =>"#{session[:freereg1_csv_file_id]}")

  
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
    unless session[:my_own] == 'my_own'
      @people =Array.new
        @userids.each do |ids|
        @people << ids.userid
      end
  end
  
end

def download
  @freereg1_csv_file = Freereg1CsvFile.find(params[:id])
  my_file =  File.join(Rails.application.config.datafiles, @freereg1_csv_file.userid,@freereg1_csv_file.file_name)
  send_file( my_file, :filename => @freereg1_csv_file.file_name)
 
end

end
