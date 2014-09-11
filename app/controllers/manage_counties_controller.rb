class ManageCountiesController < ApplicationController

	 
def index
 
  clean_session
  session[:role] = 'counties'
  session[:return] = request.referer
  get_user_info(session[:userid],session[:first_name])
 
  @counties = @user.county_groups
  @countries = @user.country_groups
   if  @user.person_role == 'data_manager' || @user.person_role == 'system_administrator'
     @countries = Array.new
    counties = County.all.order_by(chapman_code: 1)
    counties.each do |county|
      @countries << county.chapman_code
    end
   end
   unless @countries.nil?
    @counties = Array.new if @counties.nil?
     @countries.each do |county|
        @counties << county if @counties.nil?
        @counties << county unless  @counties.include?(county) 
     end
   end
   @number_of_counties = @counties.length

   redirect_to manage_resource_path(@user) if @number_of_counties == 0
   @manage_county = ManageCounty.new
    if @number_of_counties == 1 
       session[:multiple] = false
        session[:chapman_code] = @counties[0]
        @county = ChapmanCode.has_key(@counties[0])
        session[:county] = @county
    else
       session[:multiple] = true
   end
      
end


def new
  	@manage_county = ManageCounty.new
    @userid = session[:userid]
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
     redirect_to places_path
 
 end #end new

def select
    @manage_county = ManageCounty.new
    @userid = session[:userid]
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
    @county = session[:county]
    @files = Array.new
    Freereg1CsvFile.where(:county => ChapmanCode.values_at(@county)).all.order_by(file_name: 1).each do |file|
      @files << file.file_name
    end
end

 def create
  # Select is the normal option Select File is there when user selects a single file
    if params[:commit] == 'Select' then
    if session[:multiple] == true
      session[:chapman_code] = params[:manage_county][:chapman_code]
      @county = ChapmanCode.has_key(session[:chapman_code])
      session[:county] = @county
    end
      case 

      when params[:manage_county][:action] == 'Work with All Places'
        session[:active_place] = 'All'
         redirect_to places_path
          return
       when params[:manage_county][:action] == 'Work with Active Places'
        session[:active_place] = 'Active'
         redirect_to places_path
          return    
       when params[:manage_county][:action] == 'Upload New Batch'
         redirect_to new_csvfile_path
         return
      when params[:manage_county][:action] == 'Review a specific Batch'
        redirect_to select_manage_county_path
        return
       when params[:manage_county][:action] == 'Review Batches listed by filename'
          session[:sort] =  sort = "file_name ASC"    
        when params[:manage_county][:action] == 'Review Batches with errors'
          session[:sort] =  sort = "error DESC, file_name ASC" 
        when params[:manage_county][:action] == 'Review Batches listed by userid then filename'
           session[:sort] =  sort = "userid_lower_case ASC, file_name ASC"
        when params[:manage_county][:action] == 'Review Batches listed by uploaded date'
           session[:sort] =  sort = "uploaded_date DESC"

        end
          redirect_to freereg1_csv_files_path
          return
      end
       @freereg1_csv_files = Freereg1CsvFile.where(:county => session[:chapman_code],:file_name =>params[:manage_county][:places]).all.page(params[:page]) 
       if @freereg1_csv_files.length == 1
       file = @freereg1_csv_files.first
       redirect_to freereg1_csv_file_path(file)
       return
       else
        @first_name = session[:first_name]
        @user = UseridDetail.where(:userid => session[:userid]).first
       @county = ChapmanCode.has_key(session[:chapman_code])
       render 'freereg1_csv_files/index'
     end

  end # create


end
