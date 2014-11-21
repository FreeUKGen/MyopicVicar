class ManageCountiesController < ApplicationController

def index
  redirect_to :action => 'new'
end
def new
  #get county to be used
  session[:chapman_code] = nil
  session[:county] = nil
  session[:my_own] = false
  get_user_info_from_userid
  get_counties_for_selection
  if @number_of_counties == 0 
    flash[:notice] = 'You do not have any counties to manage'
    redirect_to new_manage_resource_path 
    return
  end
  if @number_of_counties == 1 
    session[:chapman_code] = @counties[0]
    @county = ChapmanCode.has_key(@counties[0])
    session[:county] = @county
    redirect_to :action => 'select_action?'
    return
  end
  @options = @counties
  @prompt = 'Please select a County'
  @location = 'location.href= "/manage_counties/select_action?county=" + this.value'
  @manage_county = ManageCounty.new
end

def select_action
   get_user_info_from_userid
  if session[:chapman_code].nil? || session[:chapman_code] != params[:county]
    session[:chapman_code] = params[:county]
    @county = ChapmanCode.has_key(session[:chapman_code])
    session[:county] = @county
  end
  @manage_county = ManageCounty.new
  @options= UseridRole::COUNTY_MANAGEMENT_OPTIONS
  @prompt = 'Select Action?'
end

def work_all_places
  get_user_info_from_userid
  session[:active_place] = 'All'
  redirect_to places_path
end

def work_with_active_places
   get_user_info_from_userid
  session[:active_place] = 'Active'
  redirect_to places_path
  return    
end
def batches_with_errors
  get_user_info_from_userid
  @county = session[:county]
  @who = nil
  @sorted_by = '(Sorted by descending number of errors and then filename)'
  @freereg1_csv_files = Freereg1CsvFile.county(session[:chapman_code]).order_by("error DESC, file_name ASC" ).page(params[:page])
  render 'freereg1_csv_files/index'
end
def display_by_filename
  get_user_info_from_userid
  @county = session[:county]
  @who = nil
  @sorted_by = '(Sorted alphabetically by file name)'
  @freereg1_csv_files = Freereg1CsvFile.county(session[:chapman_code]).order_by("file_name ASC").page(params[:page])
  render 'freereg1_csv_files/index'
end
def upload_batch
 redirect_to new_csvfile_path
end
def display_by_userid_filename
  get_user_info_from_userid
  @county = session[:county]
  @who = nil
  @sorted_by = '(Sorted by userid then alphabetically by file name)'
  @freereg1_csv_files = Freereg1CsvFile.county(session[:chapman_code]).order_by("userid_lower_case ASC, file_name ASC").page(params[:page])
  render 'freereg1_csv_files/index'
end

def display_by_descending_uploaded_date
 get_user_info_from_userid
 @county = session[:county]
 @who = nil
 @sorted_by = '(Sorted by descending date of uploading)'
 @freereg1_csv_files = Freereg1CsvFile.county(session[:chapman_code]).order_by("uploaded_date DESC").page(params[:page])
 render 'freereg1_csv_files/index'
end

def display_by_ascending_uploaded_date
  get_user_info_from_userid
  @county = session[:county]
  @who = nil
  @sorted_by = '(Sorted by ascending date of uploading)'
  @freereg1_csv_files = Freereg1CsvFile.county(session[:chapman_code]).order_by("uploaded_date ASC").page(params[:page])
  render 'freereg1_csv_files/index'
end

def review_a_specific_batch
  get_user_info_from_userid
  @manage_county = ManageCounty.new
  @county = session[:county]
  @files = Array.new
  Freereg1CsvFile.county(session[:chapman_code]).order_by(file_name: 1).each do |file|
    @files << file.file_name
  end
  @options = @files
  @location = 'location.href= "/manage_counties/files?params=" + this.value'
  @prompt = 'Select batch'
  render '_form'
end
def files 
   get_user_info_from_userid
   @county = session[:county]
  @freereg1_csv_files = Freereg1CsvFile.where(:county => session[:chapman_code],:file_name =>params[:params]).all.page(params[:page]) 
  if @freereg1_csv_files.length == 1
   file = Freereg1CsvFile.where(:county => session[:chapman_code],:file_name =>params[:params]).first
   redirect_to freereg1_csv_file_path(file)
   return
 else
   render 'freereg1_csv_files/index'
 end
end 

def get_counties_for_selection
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
end

end
