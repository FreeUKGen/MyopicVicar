class ManageCountiesController < ApplicationController

  def index
    redirect_to :action => 'new'
  end
  def new
    #get county to be used
   
    clean_session_for_county
    session.delete(:county) 
    session.delete(:chapman_code)
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
      redirect_to :action => 'select_action'
      return
    end
    @options = @counties
    @prompt = 'You have access to multiple counties, please select one'
    @manage_county = ManageCounty.new
  end
  def show
    redirect_to :action => 'new'
  end
   def selection
    redirect_to :action => 'new'
  end
  def create
    session[:chapman_code] = params[:manage_county][:chapman_code]
    @county = ChapmanCode.has_key(session[:chapman_code])
    session[:county] = @county
    redirect_to :action => 'select_action'
      return
  end

  def select_action
    clean_session_for_county
    get_user_info_from_userid
    @county =  session[:county]
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
  def work_with_specific_place
    get_user_info_from_userid
    @manage_county = ManageCounty.new
    @county = session[:county]
    @places = Array.new
    Place.where(:chapman_code => session[:chapman_code],:disabled => 'false').order_by(place_name: 1).each do |place|
      @places << place.place_name
    end
    @options = @places
    @location = 'location.href= "/manage_counties/places?params=" + this.value'
    @prompt = 'Select Place'
    render '_form_for_selection'
  end
  def places_with_unapproved_names
    if params[:page]
    session[:files_index_page] = params[:page]
    end
    get_user_info_from_userid
    @manage_county = ManageCounty.new
    @county = session[:county]
    @places = Array.new
    Place.where(:chapman_code => session[:chapman_code],:disabled => 'false', :error_flag => "Place name is not approved").order_by(place_name: 1).each do |place|
      @places << place.place_name
    end
    @options = @places
    @location = 'location.href= "/manage_counties/places?params=" + this.value'
    @prompt = 'Select Place'
  render '_form_for_selection'
  end
  def batches_with_errors
    if params[:page]
    session[:files_index_page] = params[:page]
    end
    get_user_info_from_userid
    @county = session[:county]
    @who = nil
    @sorted_by = '(Sorted by descending number of errors and then filename)'
     session[:sorted_by] = @sorted_by
    session[:sort] = "error DESC, file_name ASC"
    @freereg1_csv_files = Freereg1CsvFile.county(session[:chapman_code]).gt(error: 0).order_by("error DESC, file_name ASC" ).page(params[:page])
    render 'freereg1_csv_files/index'
  end
  def display_by_filename
    if params[:page]
    session[:files_index_page] = params[:page]
    end
    get_user_info_from_userid
    @county = session[:county]
    @who = nil
    @sorted_by = '(Sorted alphabetically by file name)'
    session[:sorted_by] = @sorted_by
    session[:sort] = "file_name ASC"
    @freereg1_csv_files = Freereg1CsvFile.county(session[:chapman_code]).order_by("file_name ASC").page(params[:page])
    render 'freereg1_csv_files/index'
  end
  def upload_batch
    redirect_to new_csvfile_path
  end
  def display_by_userid_filename
    if params[:page]
    session[:files_index_page] = params[:page]
    end
    get_user_info_from_userid
    @county = session[:county]
    @who = nil
    @sorted_by = '(Sorted by userid then alphabetically by file name)'
    session[:sorted_by] = @sorted_by
    session[:sort] = "userid_lower_case ASC, file_name ASC"
    @freereg1_csv_files = Freereg1CsvFile.county(session[:chapman_code]).order_by("userid_lower_case ASC, file_name ASC").page(params[:page])
    render 'freereg1_csv_files/index'
  end

  def display_by_descending_uploaded_date
    if params[:page]
    session[:files_index_page] = params[:page]
    end
    get_user_info_from_userid
    @county = session[:county]
    @who = nil
    @sorted_by = '(Sorted by descending date of uploading)'
    session[:sorted_by] = @sorted_by
    session[:sort] = "uploaded_date DESC"
    @freereg1_csv_files = Freereg1CsvFile.county(session[:chapman_code]).order_by("uploaded_date DESC").page(params[:page])
    render 'freereg1_csv_files/index'
  end

  def display_by_ascending_uploaded_date
    if params[:page]
    session[:files_index_page] = params[:page]
    end
    get_user_info_from_userid
    @county = session[:county]
    @who = nil
    @sorted_by = '(Sorted by ascending date of uploading)'
    session[:sorted_by] = @sorted_by
    session[:sort] ="uploaded_date ASC"
    @freereg1_csv_files = Freereg1CsvFile.county(session[:chapman_code]).order_by("uploaded_date ASC").page(params[:page])
    render 'freereg1_csv_files/index'
  end

  def review_a_specific_batch
    get_user_info_from_userid
    @manage_county = ManageCounty.new
    @county = session[:county]
    @files = Hash.new
    Freereg1CsvFile.county(session[:chapman_code]).order_by(file_name: 1).each do |file|
      @files["#{file.file_name}:#{file.userid}"] = file._id unless file.file_name.nil?
    end
    @options = @files
    @location = 'location.href= "/freereg1_csv_files/" + this.value'
    @prompt = 'Select batch'
    render '_form_for_selection'
  end
  def files
    if params[:page]
    session[:files_index_page] = params[:page]
    end
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
  def places
    if params[:page]
    session[:place_index_page] = params[:page]
    end
    get_user_info_from_userid
    @county = session[:county]
    @places = Place.where(:chapman_code => session[:chapman_code],:place_name =>params[:params]).all.page(params[:page])
    if @places.length == 1
      place = Place.where(:chapman_code => session[:chapman_code],:place_name =>params[:params]).first
      redirect_to place_path(place)
      return
    else
      render 'places/index'
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
