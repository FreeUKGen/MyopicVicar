class ManageCountiesController < ApplicationController

  def index
  #get county to be used
  p "index"
  p params
  get_user_info(session[:userid],session[:first_name])
  session[:role] = 'counties'
  get_counties_for_selection(params[:option])
  session[:chapman_code] = nil
  if @number_of_counties == 0 
    redirect_to new_manage_resource_path 
    return
  end
  session[:multiple] = true
  if @number_of_counties == 1 
    session[:chapman_code] = @counties[0]
    @county = ChapmanCode.has_key(@counties[0])
    session[:county] = @county
    session[:multiple] = false
    redirect_to :action => 'select_action'
    return
  end
  @options = @counties
  @prompt = 'County?'
  @location = 'location.href= "/manage_counties/select_action?county=" + this.value'
  @manage_county = ManageCounty.new
  render '_form'
end

def select_action
  if session[:multiple] == true
    session[:chapman_code] = params[:county]
    @county = ChapmanCode.has_key(session[:chapman_code])
    session[:county] = @county
  end
   @manage_county = ManageCounty.new
    @options =['Work with All Places', 'Work with Active Places','Review Batches with errors','Review Batches listed by filename', 'Upload New Batch',
    'Review Batches listed by userid then filename','Review Batches listed by uploaded date','Review a specific Batch']
    @location = 'location.href= "/manage_counties/select?option=" + this.value'
    @prompt = 'Select Action?'
    render '_form'
  end
  def select
    p "selecting"
    p params
    case 
    when params[:option] == 'Work with All Places'
      session[:active_place] = 'All'
      redirect_to places_path
      return
    when params[:option] == 'Work with Active Places'
      session[:active_place] = 'Active'
      redirect_to places_path
      return    
    when params[:option] == 'Upload New Batch'
      redirect_to new_csvfile_path
      return
    when params[:option] == 'Review a specific Batch'
      redirect_to select_file_manage_counties_path
      return
    when params[:option] == 'Review Batches listed by filename'
      session[:sort] =  sort = "file_name ASC"    
    when params[:option] == 'Review Batches with errors'
      session[:sort] =  sort = "error DESC, file_name ASC" 
    when params[:option] == 'Review Batches listed by userid then filename'
      session[:sort] =  sort = "userid_lower_case ASC, file_name ASC"
    when params[:option] == 'Review Batches listed by uploaded date'
      session[:sort] =  sort = "uploaded_date DESC"
    else
      p "failure"
      flash[:notice] = 'Invalid option'
      redirect_to :back
      return 
    end
    redirect_to freereg1_csv_files_path
    return
  end

  def select_file
    get_user_info(session[:userid],session[:first_name])
    @manage_county = ManageCounty.new
    @county = session[:county]
     p @county
    @files = Array.new
    Freereg1CsvFile.where(:county => ChapmanCode.values_at(@county)).all.order_by(file_name: 1).each do |file|
      @files << file.file_name
    end
    @options = @files
    @location = 'location.href= "/manage_counties/files?params=" + this.value'
    @prompt = 'Select file'
    render '_form'
  end

  def files 
    p "file selection"
  p params 
    get_user_info(session[:userid],session[:first_name]) 
   @freereg1_csv_files = Freereg1CsvFile.where(:county => session[:chapman_code],:file_name =>params[:params]).all.page(params[:page]) 
   if @freereg1_csv_files.length == 1
     file = @freereg1_csv_files.first
     redirect_to freereg1_csv_file_path(file)
     return
   else
    @county = ChapmanCode.has_key(session[:chapman_code])
    render 'freereg1_csv_files/index'
  end
end 

def get_counties_for_selection(option)
  @counties = @user.county_groups
  @countries = @user.country_groups
  if  option == 'all' 
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
end

end
