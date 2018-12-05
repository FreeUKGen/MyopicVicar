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

  def display_by_zero_date
    get_user_info_from_userid
    @county = session[:county]
    @who = @user.person_forename
    @sorted_by = '; selects files with zero date records then alphabetically by userid and file name'
    session[:sorted_by] = @sorted_by
    session[:sort] = "userid_lower_case ASC, file_name ASC"
    @freereg1_csv_files = Freereg1CsvFile.county(session[:chapman_code]).datemin('0').no_timeout.order_by(session[:sort]).page(params[:page]).per(FreeregOptionsConstants::FILES_PER_PAGE)
    render 'freereg1_csv_files/index'
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

  def manage_completion_submitted_image_group
    get_user_info_from_userid
    session.delete(:from_source)
    session[:image_group_filter] = 'completion_submitted'

    if session[:chapman_code].nil?
      redirect_to main_app.new_manage_resource_path
      return
    else
      @source,@group_ids,@group_id = ImageServerGroup.group_ids_sort_by_place(session[:chapman_code], 'completion_submitted')            # not sort by place, unallocated groups
      @county = session[:county]
      # for 'Accept All Groups As Completed'
      @completed_groups = []
      @group_ids.each {|x| @completed_groups << x[0]}
      @dummy = @completed_groups[0]
      flash[:notice] = 'No Completion Submitted Image Group exists' if @source.nil? || @group_ids.empty? || @group_id.empty?

      render 'image_server_group_completion_submitted'
    end
  end

  def manage_image_group
    get_user_info_from_userid
    clean_session_for_managed_images
    session[:image_group_filter] = 'all'

    if session[:chapman_code].nil?
      redirect_to main_app.new_manage_resource_path
      return
    else
      @source,@group_ids,@group_id = ImageServerGroup.group_ids_sort_by_place(session[:chapman_code])                   # not sort by place, all groups
      @county = session[:county]

      if @source.nil? || @group_ids.empty? || @group_id.empty?
        redirect_to(:back, :notice => 'No Image Groups exists') and return
      else
        render 'image_server_group_all'
      end
    end
  end

  def manage_unallocated_image_group
    get_user_info_from_userid
    session.delete(:from_source)
    session[:image_group_filter] = 'unallocate'

    if session[:chapman_code].nil?
      redirect_to main_app.new_manage_resource_path
      return
    else
      @source,@group_ids,@group_id = ImageServerGroup.group_ids_sort_by_place(session[:chapman_code], 'unallocate')            # not sort by place, unallocated groups
      @county = session[:county]

      if @source.nil? || @group_ids.empty? || @group_id.empty?
        redirect_to(:back, :notice => 'No unallocated image groups exists') and return
      else
        render 'image_server_group_unallocate'
      end
    end
  end

  def manage_allocate_request_image_group
    get_user_info_from_userid
    session.delete(:from_source)
    session[:image_group_filter] = 'allocate request'

    if session[:chapman_code].nil?
      redirect_to main_app.new_manage_resource_path
      return
    else
      @source,@group_ids,@group_id = ImageServerGroup.group_ids_sort_by_place(session[:chapman_code], 'allocate request')            # not sort by place, unallocated groups
      @county = session[:county]

      if @source.nil? || @group_ids.empty? || @group_id.empty?
        redirect_to(:back, :notice => 'No Allocate Request Image Groups exists') and return
      else
        render 'image_server_group_allocate_request'
      end
    end
  end

  def manage_sources
    get_user_info_from_userid
    clean_session_for_images
    session[:manage_user_origin] = 'manage county'

    if session[:chapman_code].nil?
      flash[:notice] = 'Your other actions cleared the county information, please select county again'
      redirect_to main_app.new_manage_resource_path
      return
    else
      @source_ids,@source_id = Source.get_source_ids(session[:chapman_code])
      @county = session[:county]

      if @source_ids.nil? || @source_id.nil?
        flash[:notice] = 'No requested Sources exists'
        redirect_to :back
      elsif @source_ids.empty? || @source_id.empty?
        flash[:notice] = 'No requested Sources exists'
        redirect_to :back
      else
        render 'sources_list_all'
      end
    end
  end

  def new
    #get county to be used
    clean_session_for_county
    clean_session_for_images
    session.delete(:county)
    session.delete(:chapman_code)
    session[:manage_user_origin] = 'manage county'
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

  def sort_image_group_by_place
    get_user_info_from_userid
    session.delete(:from_source)
    session[:image_group_filter] = 'place'

    if session[:chapman_code].nil?
      flash[:notice] = 'Your other actions cleared the county information, you need to select county again'
      redirect_to main_app.new_manage_resource_path
      return
    else
      @source,@group_ids,@group_id = ImageServerGroup.group_ids_sort_by_place(session[:chapman_code], 'all')        # sort by place, all groups
      @county = session[:county]

      if @source.nil? || @group_ids.empty?
        redirect_to(:back, :notice => 'No Image Groups Allocated by Place for County ' + @county)
      else
        render 'image_server_group_by_place'
      end
    end
  end

  def sort_image_group_by_syndicate
    get_user_info_from_userid
    session.delete(:from_source)
    session[:image_group_filter] = 'syndicate'

    if session[:chapman_code].nil?
      flash[:notice] = 'Your other actions cleared the county information, you need to select county again'
      redirect_to main_app.new_manage_resource_path
      return
    else
      @source,@group_ids,@syndicate = ImageServerGroup.group_ids_sort_by_syndicate(session[:chapman_code])
      @county = session[:county]

      if @source.nil? || @group_ids.empty? || @syndicate.empty?
        redirect_to(:back, :notice => 'No Image Groups Allocated by Syndicate for County ' + @county)
      else
        render 'image_server_group_by_syndicate'
      end
    end
  end

  def uninitialized_source_list
    get_user_info_from_userid
    session.delete(:from_source)
    session[:image_group_filter] = 'uninitialized'

    if session[:chapman_code].nil?
      flash[:notice] = 'Your other actions cleared the county information, please select county again'
      redirect_to main_app.new_manage_resource_path
      return
    else
      @source_ids,@source_id = Source.get_unitialized_source_list(session[:chapman_code])
      @county = session[:county]

      if @source_ids.empty?
        flash[:notice] = 'No Uninitialized Sources'
        redirect_to selection_active_manage_counties_path(session[:chapman_code], :option =>'Manage Images')
      else
        render 'uninitialized_source_list'
      end
    end
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
