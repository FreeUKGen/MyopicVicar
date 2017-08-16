class ManageCountiesController < ApplicationController
 
  def batches_with_errors
    get_user_info_from_userid
    @county = session[:county]
    @who = @user.person_forename
    @sorted_by = '; sorted by descending number of errors and then file name'
    session[:sorted_by] = @sorted_by
    session[:sort] = "error DESC, file_name ASC"
    redirect_to freereg1_csv_files_path
  end

  def create
    if params[:manage_county].blank? || params[:manage_county][:chapman_code].blank?
      flash[:notice] = 'You did not selected anything'
      redirect_to :action => 'new'
      return
    end
    session[:chapman_code] = params[:manage_county][:chapman_code]
    @county = ChapmanCode.has_key(session[:chapman_code])
    session[:county] = @county
    redirect_to :action => 'select_action'
    return
  end

  def files
    get_user_info_from_userid
    @county = session[:county]
    @freereg1_csv_files = Freereg1CsvFile.where(:county => session[:chapman_code],:file_name =>params[:params]).all
    if @freereg1_csv_files.length == 1
      file = Freereg1CsvFile.where(:county => session[:chapman_code],:file_name =>params[:params]).first
      redirect_to freereg1_csv_file_path(file)
      return
    else
      redirect_to freereg1_csv_files_path
    end
  end

  def display_by_ascending_uploaded_date
    get_user_info_from_userid
    @county = session[:county]
    @who = @user.person_forename
    @sorted_by = '; sorted by ascending date of uploading'
    session[:sorted_by] = @sorted_by
    session[:sort] ="uploaded_date ASC"
    redirect_to freereg1_csv_files_path
  end

  def display_by_descending_uploaded_date
    get_user_info_from_userid
    @county = session[:county]
    @who = @user.person_forename
    @sorted_by = '; sorted by descending date of uploading'
    session[:sorted_by] = @sorted_by
    session[:sort] = "uploaded_date DESC"
    redirect_to freereg1_csv_files_path
  end

  def display_by_filename
    get_user_info_from_userid
    @county = session[:county]
    @who = @user.person_forename
    @sorted_by = '; sorted alphabetically by file name'
    session[:sorted_by] = @sorted_by
    session[:sort] = "file_name ASC"
    redirect_to freereg1_csv_files_path
  end


  def display_by_userid_filename
    get_user_info_from_userid
    @county = session[:county]
    @who = @user.person_forename
    @sorted_by = '; sorted by userid then alphabetically by file name'
    session[:sorted_by] = @sorted_by
    session[:sort] = "userid_lower_case ASC, file_name ASC"
    redirect_to freereg1_csv_files_path
  end

  def get_counties_for_selection
    @counties = @user.county_groups
    @countries = @user.country_groups
    if  @user.person_role == 'data_manager' || @user.person_role == 'system_administrator' ||
        @user.person_role == 'documentation_coordinator' || @user.person_role == "contacts_coordinator"
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
    @counties = @counties.compact unless @counties.nil?
  end

  def index
    redirect_to :action => 'new'
  end

  def manage_images
    get_user_info_from_userid
    @source_id = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

    @county = session[:chapman_code]
    @place_id = Place.chapman_code(session[:chapman_code]).pluck(:id, :place_name).to_h

    @church = Church.find_by_place_ids(@place_id).pluck(:id, :place_id, :church_name)
    @church_id = Hash.new{|h,k| h[k]=[]}.tap{|h| @church.each{|k,v,w| h[k] << v << w}}

    @register = Register.find_by_church_ids(@church_id).pluck(:id, :church_id, :register_type)
    @register_id = Hash.new{|h,k| h[k]=[]}.tap{|h| @register.each{|k,v,w| h[k] << v << w}}

    @source = Source.find_by_register_ids(@register_id).pluck(:id, :register_id, :source_name)
    x = Hash.new{|h,k| h[k]=[]}.tap{|h| @source.each{|k,v,w| h[k] << v << w}}
    x.each do |k1,v1|
      # build array @source_id[place_name][church_name][register_type][source_name] = source_id
      @source_id[@place_id[@church_id[@register_id[v1[0]][0]][0]]][@church_id[@register_id[v1[0]][0]][1]][@register_id[v1[0]][1]][v1] = k1
    end

    render '_sources_index'
  end

  def new
    #get county to be used
    clean_session_for_county
    session.delete(:county)
    session.delete(:chapman_code)
    get_user_info_from_userid
    get_counties_for_selection
    number_of_counties = 0
    number_of_counties = @counties.length unless @counties.nil?
    if number_of_counties == 0
      flash[:notice] = 'You do not have any counties to manage'
      redirect_to new_manage_resource_path
      return
    end
    if number_of_counties == 1
      session[:chapman_code] = @counties[0]
      @county = ChapmanCode.has_key(@counties[0])
      session[:county] = @county
      redirect_to :action => 'select_action'
      return
    end
    @options = @counties
    @prompt = 'Please select one'
    @manage_county = ManageCounty.new
    @location = 'location.href= "/manage_counties/" + this.value +/selected/'
  end

  def place_range
    if params[:params].present? || session[:character].present?
      session[:character]  = params[:params] if params[:params].present?
      @character = session[:character]
      @county = session[:county]
      get_user_info_from_userid
      @active = session[:active_place]
      if session[:active_place]
        @all_places = Place.chapman_code(session[:chapman_code]).not_disabled.data_present.all.order_by(place_name: 1)
      else
        @all_places = Place.chapman_code(session[:chapman_code]).not_disabled.all.order_by(place_name: 1)
      end
      @places = Array.new
      @all_places.each do |place|
        @places << place if place.place_name =~  Regexp.new(/^[#{@character}]/)
      end

      # TODO at some point consider place/churches/registers hash

    else
      flash[:notice] = 'You did not make a range selection'
      redirect_to :action => 'select_action'
      return
    end
  end

  def places
    get_user_info_from_userid
    @county = session[:county]
    @places = Place.where(:chapman_code => session[:chapman_code],:place_name =>params[:params],:disabled => 'false').all
    if @places.length == 1
      place = Place.where(:chapman_code => session[:chapman_code],:place_name =>params[:params],:disabled => 'false').first
      redirect_to place_path(place)
      return
    else
      render 'places/index'
    end
  end

  def places_with_unapproved_names
    get_user_info_from_userid
    session[:select_place] = true
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

  def selected
    session[:chapman_code] = params[:id]
    @county = ChapmanCode.has_key(session[:chapman_code])
    session[:county] = @county
    redirect_to :action => 'select_action'

  end

  def selection
    redirect_to :action => 'new'
  end

  def select_action
    clean_session_for_county
    get_user_info_from_userid
    @county =  session[:county]
    @manage_county = ManageCounty.new
    @options= UseridRole::COUNTY_MANAGEMENT_OPTIONS
    @prompt = 'Select Action?'
  end
  def show
    redirect_to :action => 'new'
  end



  def upload_batch
    redirect_to new_csvfile_path
  end

  def work_all_places
    get_user_info_from_userid
    session[:active_place] = false
    work_places_core
  end

  def work_places_core
    show_alphabet = ManageCounty.records(session[:chapman_code],session[:show_alphabet])
    session[:show_alphabet] = show_alphabet
    if show_alphabet == 0
      redirect_to places_path
      return
    else
      @active = session[:active_place]
      @manage_county = ManageCounty.new
      @county = session[:county]
      session[:show_alphabet] = show_alphabet
      @options = FreeregOptionsConstants::ALPHABETS[show_alphabet]
      @location = 'location.href= "/manage_counties/place_range?params=" + this.value'
      @prompt = 'Select Place Range'
      render '_form_for_range_selection'
      return
    end
  end

  def work_with_active_places
    get_user_info_from_userid
    session[:active_place] = true
    work_places_core
  end

  def work_with_specific_place
    get_user_info_from_userid
    session[:select_place] = true
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

end
