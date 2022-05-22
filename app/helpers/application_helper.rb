# Copyright 2012 Trustees of FreeBMD
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module ApplicationHelper
  def nav_search_form_link
    link_to('Search', main_app.new_search_query_path) unless controller_name.nil? || controller_name == 'search_queries' || controller_name == 'search_records'
  end

  def nav_actions_page_link
    return if session[:userid_detail_id].blank?

    link_to 'Your Actions', main_app.new_manage_resource_path
  end

  def nav_about_page_link
    return if session[:userid_detail_id].present?

    link_to 'About', '/cms/about'
  end

  def nav_donate_page_link
    # not currently in use
    link_to 'Donate', "https://www.freeukgenealogy.org.uk/help-us-keep-history-free/", id: 'donate_nav', target: :_blank
  end

  def nav_help_pages_link
    if session[:userid_detail_id].present? || controller_name == 'sessions'
      get_user_info_from_userid
      if @user.present? && @user.person_role.present?
        if @user.person_role == 'transcriber' || @user.person_role == 'trainee' || @user.person_role == 'pending'
          if controller_name == 'pages'
            link_to 'Help', '/cms/help'
          else
            link_to 'Help', '/cms/information-for-transcribers'
          end
        elsif @user.person_role == 'researcher'
          if controller_name == 'pages'
            link_to 'Help', '/cms/help'
          else
            link_to 'Help', '/cms/registered-researchers'
          end
        else
          if controller_name == 'pages'
            link_to 'Help', '/cms/help'
          else
            link_to 'Help', '/cms/information-for-coordinators'
          end
        end
      end
    else
      link_to 'Help', '/cms/help'
    end
  end

  def nav_member_page_link
    return if controller_name == 'sessions'

    if session[:userid_detail_id].present?
      link_to 'Logout', main_app.logout_manage_resources_path
    else
      link_to 'Member', refinery.login_path
    end
  end

  def nav_transcription_page_link
    return if controller_name == 'freecen_coverage' || controller_name == 'freecen_contents'

    case appname.downcase
    when 'freereg'
      link_to('Records', main_app.new_freereg_content_path)
    when 'freecen'
      link_to('Records', main_app.freecen2_contents_path)
    when 'freebmd'
      link_to('Records', 'https://www.freebmd.org.uk/progress.shtml', target: :_blank)
    end
  end

  def nav_volunteer_page_link
    return if session[:userid_detail_id].present?

    link_to 'Volunteer', "/cms/opportunities-to-volunteer-with-#{appname}"
  end

  def nav_freecen_gazetteer
    link_to('Gazetteer', '/freecen2_places/search_names', target: :_blank, title: 'Search for an existing place name; opens in a new tab') if
    appname.downcase == 'freecen' && session[:userid_detail_id].present?
  end

  def action_manage_image_server(role)
    action = role == 'Manage Image Server' ? true : false
    action
  end

  def app_specific_partial(partial)
    template_set = MyopicVicar::Application.config.template_set
    base_template = File.basename(partial)
    app_specific_template = base_template.sub(/$/, "_#{template_set}")
    app_specific_template
  end

  def app_partial(partial)
    template_set = MyopicVicar::Application.config.template_set
    base_template = File.basename(partial)
    app_specific_template = base_template.sub(/$/, "_search_records_#{template_set}")
    app_specific_template
  end

  def credit(entry)
    credit = nil
    file = entry.freereg1_csv_file
    register = file.register if file.present?
    credit = register.credit if register.credit.present?
    credit
  end

  def transcriber_entry(entry)
    transcriber = nil
    file = entry.freereg1_csv_file
    transcriber = file.userid_detail if file.userid_detail.present?
    answer, transcriber = UseridDetail.can_we_acknowledge_the_transcriber(transcriber) if transcriber.present?
    transcriber
  end

  def google_analytics_tracking
    google_analytics_tracking_id = ''
    case appname_downcase
    when 'freereg'
      google_analytics_tracking_id = 'UA-62395250-1'
    when 'freecen'
      if MyopicVicar::MongoConfig['website'].eql? "https://freecen2.freecen.org.uk"
        google_analytics_tracking_id = 'UA-89287207-1'
      else
        google_analytics_tracking_id = ''
      end
    when 'freebmd'
      'not implemented for FreeBMD yet -->'
    end
    google_analytics_tracking_id
  end

  def get_user_info_from_userid
    @user = get_user
    unless @user.blank?
      @first_name = @user.person_forename
      @user_id = @user.id
      @userid = @user.id
      @manager = manager?(@user)
      @roles = UseridRole::OPTIONS.fetch(@user.person_role)
    end
  end

  def get_user
    user = cookies.signed[:userid]
    user = UseridDetail.id(user).first
    return user
  end

  def manager?(user)
    #sets the manager flag status
    a = true
    a = false if (user.person_role == 'transcriber' || user.person_role == 'researcher' ||  user.person_role == 'technical')
    return a
  end

  def problem_url
    # construct url parameters for problem reports
    problem_time = Time.now.utc
    session_id = request.session['session_id']
    problem_page_url=request.env['REQUEST_URI']
    previous_page_url=request.env['HTTP_REFERER']
    feedback_type=Feedback::FeedbackType::ISSUE
    user_id = session[:userid]
    url = main_app.new_feedback_path({ :feedback_time => problem_time,
                                       :session_id => session_id,
                                       :user_id => user_id,
                                       :problem_page_url => problem_page_url,
                                       :previous_page_url => previous_page_url,
                                       :feedback_type => feedback_type })
    url
  end

  def problem_button_options
    # construct url parameters for problem reports
    problem_time = Time.now.utc
    session_id = request.session['session_id']
    problem_page_url = request.env['REQUEST_URI']
    previous_page_url = request.env['HTTP_REFERER']
    feedback_type=Feedback::FeedbackType::ISSUE
    user_id = session[:userid]

    {  :feedback_time => problem_time,
       :session_id => session_id,
       :user_id => user_id,
       :problem_page_url => problem_page_url,
       :previous_page_url => previous_page_url,
       :feedback_type => feedback_type }
  end

  #Do not believe the following is used anywhere
  def freereg1_csv_file_for_display(freereg1_csv_file)
    display_map = {}
    display_map['Register Type'] = RegisterType.display_name(freereg1_csv_file.register.register_type)
    display_map['Record Type'] = RecordType::display_name(freereg1_csv_file.record_type)
    display_map['Oldest Entry'] = freereg1_csv_file.datemin
    display_map['Newest Entry'] = freereg1_csv_file.datemax
    display_map['File Name'] = freereg1_csv_file.file_name
    display_map['Transcriber Syndicate'] = freereg1_csv_file.transcriber_syndicate
    display_map['Comment #1'] = freereg1_csv_file.first_comment if freereg1_csv_file.first_comment
    display_map['Comment #2'] = freereg1_csv_file.second_comment if freereg1_csv_file.second_comment

    display_map
  end

  # generate proper display for the search query, in display order

  def search_freecen2_params_for_display(search_query)
    search_query[:freecen2_place_ids].present? ? search_query_places_size = search_query[:freecen2_place_ids].length : search_query_places_size = 0
    if search_query_places_size > 0
      first_place = Freecen2Place.find(search_query[:freecen2_place_ids][0])
      place = first_place.place_name
      if search_query.all_radius_place_ids.length > 1
        last_place = search_query.all_radius_place_ids[-2]
        last_place = Freecen2Place.find(last_place)
        additional = search_query.all_radius_place_ids.length - 1
        place <<
        " (including #{additional} additional places within
          #{geo_near_distance(first_place,last_place,Place::MeasurementSystem::ENGLISH).round(1)}
          #{Place::MeasurementSystem::system_to_units(Place::MeasurementSystem::ENGLISH)} )"
      end
    end
    display_map = {}
    # name fields
    display_map['First Name'] = search_query.first_name.upcase if search_query.first_name
    display_map['Last Name'] = search_query.last_name.upcase if search_query.last_name
    display_map['Exact Match?'] = 'Yes' unless search_query.fuzzy
    display_map['Exact Match?'] = 'No' if search_query.fuzzy

    case appname.downcase
    when 'freereg'
      display_map['Start Year'] = search_query.start_year if search_query.start_year
      display_map['End Year'] = search_query.end_year if search_query.end_year
      display_map['Record Type'] = RecordType::display_name(search_query.record_type) if search_query.record_type
      display_map['Record Type'] = 'All' if search_query.record_type.blank?
      counties = search_query.chapman_codes.map{|code| ChapmanCode::name_from_code(code)}.join(' or ')
      display_map['Counties'] = counties if search_query.chapman_codes.size > 1
      display_map['County'] = counties if search_query.chapman_codes.size == 1
      display_map['Place'] = place if search_query_places_size > 0
      display_map['Include Family Members'] = 'Yes' if search_query.inclusive
      display_map['Include Witnesses'] = 'Yes' if search_query.witness
    when 'freecen'
      display_map['Birth Year'] = "#{search_query.start_year} - #{search_query.end_year}" if search_query.start_year || search_query.end_year
      display_map['Census Year'] = RecordType::display_name(search_query.record_type) if search_query.record_type
      display_map['Census Year'] = 'All' if search_query.record_type.blank?
      counties = search_query.birth_chapman_codes.map{|code| ChapmanCode::name_from_code(code)}.join(' or ')
      display_map['Birth Counties'] = counties if search_query.birth_chapman_codes.size > 1
      display_map['Birth County'] = counties if search_query.birth_chapman_codes.size == 1
      counties = search_query.chapman_codes.map{|code| ChapmanCode::name_from_code(code)}.join(' or ')
      display_map['Census Counties'] = counties if search_query.chapman_codes.size > 1
      display_map['Census County'] = counties if search_query.chapman_codes.size == 1
      display_map['Census Place'] = place if search_query_places_size > 0
      display_map['Disabled'] = 'Yes' if search_query.disabled
      display_map['Sex'] = search_query.sex if search_query.sex.present?
      display_map['Marital Status'] = search_query.marital_status if search_query.marital_status.present?
      display_map['Language'] = search_query.language if search_query.language.present?
      display_map['Occupation'] = search_query.occupation if search_query.occupation.present?
    end
    display_map
  end

  # needs rationalization for cen
  def search_params_for_display(search_query)
    search_query[:place_ids].present? ? search_query_places_size = search_query[:place_ids].length : search_query_places_size = 0
    if search_query_places_size > 0
      first_place = search_query[:place_ids][0]
      first_place = Place.find(first_place) if appname.downcase == 'freereg'
      if appname.downcase == 'freecen'
        first_place = Place.find(search_query[:place_ids][0])
        if first_place.blank?
          first_place = Freecen2Place.find(search_query[:place_ids][0])
        end
      end
      place = first_place.place_name
      if search_query.all_radius_place_ids.length > 1
        last_place = search_query.all_radius_place_ids[-2]
        last_place = Place.find(last_place) if appname.downcase == 'freereg'
        if appname.downcase == 'freecen'
          last_place = Place.find(last_place)
          if last_place.blank?
            last_place = Freecen2Place.find(search_query.all_radius_place_ids[-2])
          end
        end
        additional = search_query.all_radius_place_ids.length - 1
        place <<
        " (including #{additional} additional places within
          #{geo_near_distance(first_place,last_place,Place::MeasurementSystem::ENGLISH).round(1)}
          #{Place::MeasurementSystem::system_to_units(Place::MeasurementSystem::ENGLISH)} )"
      end
    end
    display_map = {}
    # name fields
    display_map['First Name'] = search_query.first_name.upcase if search_query.first_name
    display_map['Last Name'] = search_query.last_name.upcase if search_query.last_name
    display_map['Exact Match?'] = 'Yes' unless search_query.fuzzy
    display_map['Exact Match?'] = 'No' if search_query.fuzzy

    case appname.downcase
    when 'freereg'
      display_map['Start Year'] = search_query.start_year if search_query.start_year
      display_map['End Year'] = search_query.end_year if search_query.end_year
      display_map['Record Type'] = RecordType::display_name(search_query.record_type) if search_query.record_type
      display_map['Record Type'] = 'All' if search_query.record_type.blank?
      counties = search_query.chapman_codes.map{|code| ChapmanCode::name_from_code(code)}.join(' or ')
      display_map['Counties'] = counties if search_query.chapman_codes.size > 1
      display_map['County'] = counties if search_query.chapman_codes.size == 1
      display_map['Place'] = place if search_query_places_size > 0
      display_map['Include Family Members'] = 'Yes' if search_query.inclusive
      display_map['Include Witnesses'] = 'Yes' if search_query.witness
    when 'freecen'
      display_map['Birth Year'] = "#{search_query.start_year} - #{search_query.end_year}" if search_query.start_year || search_query.end_year
      display_map['Census Year'] = RecordType::display_name(search_query.record_type) if search_query.record_type
      display_map['Census Year'] = 'All' if search_query.record_type.blank?
      counties = search_query.birth_chapman_codes.map{|code| ChapmanCode::name_from_code(code)}.join(' or ')
      display_map['Birth Counties'] = counties if search_query.birth_chapman_codes.size > 1
      display_map['Birth County'] = counties if search_query.birth_chapman_codes.size == 1
      counties = search_query.chapman_codes.map{|code| ChapmanCode::name_from_code(code)}.join(' or ')
      display_map['Census Counties'] = counties if search_query.chapman_codes.size > 1
      display_map['Census County'] = counties if search_query.chapman_codes.size == 1
      display_map['Census Place'] = place if search_query_places_size > 0
      display_map['Disabled'] = 'Yes' if search_query.disabled
      display_map['Sex'] = search_query.sex if search_query.sex.present?
      display_map['Marital Status'] = search_query.marital_status if search_query.marital_status.present?
      display_map['Language'] = search_query.language if search_query.language.present?
      display_map['Occupation'] = search_query.occupation if search_query.occupation.present?
    end
    display_map
  end

  def geo_near_distance(first, last, units)
    if first.present? && last.present?
      dist = Geocoder::Calculations.distance_between([first.latitude, first.longitude], [last.latitude, last.longitude], { units: :mi }) if units == Place::MeasurementSystem::ENGLISH
      dist = Geocoder::Calculations.distance_between([first.latitude, first.longitude], [last.latitude, last.longitude], { units: :km }) if units == Place::MeasurementSystem::SI
    else
      dist = 500
    end
    dist
  end

  def title(title = nil)
    if title.present?
      content_for :title, title
    elsif content_for?(:title)
      title = content_for(:title) +  ' | ' + 'FreeREG'

    elsif  page_title.present?
      title = page_title + ' | '  + 'FreeREG'
    else
      title = 'FreeREG | UK Parish Register Records'
    end
  end
  def display_number(num)
    number_with_delimiter(num, :delimiter => ',')
  end

  def witness_search_enabled?
    Rails.application.config.respond_to?(:witness_support) && Rails.application.config.witness_support
  end

  def ucf_wildcards_enabled?
    Rails.application.config.respond_to?(:ucf_support) && Rails.application.config.ucf_support
  end

  def valid_directory?
    File.directory?(output_directory_path)
  end

  # Create a new file named as current date and time
  def new_file(name)
    raise 'Not a Valid Directory' unless valid_directory?

    file_name = "#{Time.now.strftime("%Y%m%d%H%M%S")}_#{name}.txt"
    "#{output_directory_path}/#{file_name}"
  end

  # Set an output directory
  # If there is no ouput directory, then set the default
  # else check the trailing slash at the end of the directory
  def output_directory_path
    if @output_directory.nil?
      directory = File.join(Rails.root, 'script')
    else
      directory = File.join(@output_directory, '')
    end
    directory
  end

  def delete_file_if_exists(name)
    File.delete(*Dir.glob("#{output_directory_path}/*_#{name}.txt"))
  end

  def to_boolean(value)
    case value
    when true, 'true', 1, '1', 't' then true
    when false, 'false', nil, '', 0, '0', 'f' then false
    when nil, 'nil' then nil
    else
      raise ArgumentError, "invalid value for Boolean(): \"#{value.inspect}\""
    end
  end

  def church_name(file)
    church_name = file.church_name
    if church_name.blank?
      register = get_register_object(file)
      church = get_church_object(register)
      church_name = church.church_name unless church.blank?
    end
    church_name
  end

  def userid(file)
    userid = file.userid
  end

  def register_name_for_entry(entry)
    #expecting the field
    if RegisterType.approved_option_values.include?(entry)
      register_name = RegisterType::display_name(entry)
    else
      register_name = entry
    end
    register_name
  end

  def register_name_for_file(file)
    register = file.register
    register_name = register.blank? ? 'File does not belong to a register' : RegisterType::display_name(register.register_type)
    register_name
  end

  def look_up_entry_chain(entry)
    @file = entry.freereg1_csv_file
    @register = @file.register
    if @register.blank?
      @church = nil
      @place = nil
      @county = nil
    else
      @church = @register.church
      if @church.blank?
        @place = nil
        @county = nil
      else
        @place = @church.place
        @county = @place.present? ? @place.county : nil
      end
    end
  end

  def county_name_for_entry
    county_name = @county.present? ? @county : 'Unknown county'
  end
  def place_name_for_entry
    place_name = @place.present? ? @place.place_name : 'Unknown place'
  end
  def church_name_for_entry
    church_name = @church.present? ? @church.church_name : 'Unknown church'
  end
  def register_name_for_entry
    register_name = @register.blank? ? 'File does not belong to a register' : RegisterType::display_name(@register.register_type)
  end

  def county_name(file)
    county_name = file.county #note county has chapman in file and record)
    case
    when ChapmanCode.value?(county_name)
      county_name = ChapmanCode.name_from_code(county_name)
    when ChapmanCode.key?(county_name)
    else
      register = get_register_object(file)
      church = get_church_object(register)
      place = get_place_object(church)
      county_name = place.county unless place.blank?
    end
    county_name
  end

  def chapman(file)
    chapman = file.county
    return chapman if  ChapmanCode.value?(chapman)
    return ChapmanCode.value_at(chapman) if ChapmanCode.has_key?(chapman)
    register = get_register_object(file)
    church = get_church_object(register)
    place = get_place_object(church)
    chapman = place.chapman_code unless place.blank?
    chapman
  end

  def place_name(file)
    place_name = file.place
    if place_name.blank?
      register = get_register_object(file)
      church = get_church_object(register)
      place = get_place_object(church)
      place_name = place.place_name unless place.blank?
    end
    place_name
  end

  def owner(file)
    owner = file.userid
  end

  def processed_date(file)
    if file.processed_date.nil?
      physical_file = PhysicalFile.file_name(file.file_name).userid(file.userid).first
      if physical_file.present? && physical_file.file_processed_date.present?
        processed_date = physical_file.file_processed_date.strftime("%d/%m/%Y")
        file.update_attribute(:processed_date, physical_file.file_processed_date)
      else
        processed_date = ''
      end
    else
      processed_date = file.processed_date.strftime("%d/%m/%Y")
    end
    processed_date
  end

  def uploaded_date(file)
    uploaded_date = file.uploaded_date.nil? ? '' : file.uploaded_date.strftime("%d/%m/%Y")
  end

  def system_administrator(user)
    system_administrator = user.user_role == 'system_administrator' ? true : false
  end

  def get_register_object(file)
    register = file.register unless file.blank?
  end

  def get_church_object(register)
    church = register.church unless register.blank?
  end

  def get_place_object(church)
    place = church.place unless church.blank?
  end

  def uploaded_date(file)
    file.uploaded_date.strftime("%d %b %Y") unless file.uploaded_date.nil?
  end

  def file_name(file)
    file.file_name[0..-5]  unless file.file_name.nil?
  end

  def locked_by_transcriber(file)
    if file.locked_by_transcriber
      value = 'Y'
    else
      value = 'N'
    end
    value
  end

  def locked_by_coordinator(file)
    if file.locked_by_coordinator
      value = 'Y'
    else
      value = 'N'
    end
    value
  end

  def base_uploaded_date(file)
    file.base_uploaded_date.strftime("%d %b %Y") unless file.base_uploaded_date.nil?
  end

  def waiting_date(file)
    file.waiting_date.strftime("%d %b %Y") unless file.waiting_date.nil?
  end

  def errors(file)
    if file.error >= 0
      errors = file.error
    else
      errors = 0
    end
    errors
  end

  def calculate_total(array)
    array.inject(0){|sum,x| sum + x }
  end

  def freecen1_link_text
    content_tag :span, 'You can visit the old FreeCEN website here -'
  end

  def fullwidth_adsense
    case MyopicVicar::Application.config.template_set
    when 'freecen'
      fullwidth_adsense_freecen
    when 'freereg'
      fullwidth_adsense_freereg
    end
  end

  def app_advert
    MyopicVicar::Application.config.advert_key
  end

  def data_ad_client
    app_advert['data_ad_client']
  end

  def data_ad_slot_header
    app_advert['data_ad_slot_header']
  end

  def data_ad_slot_google_advert
    app_advert['data_ad_slot_google_advert']
  end

  def data_ad_slot_coverage
    app_advert['data_ad_slot_coverage']
  end

  def data_ad_slot_fullwidth
    app_advert['data_ad_slot_fullwidth']
  end

  def gtm_key_value
    MyopicVicar::Application.config.gtm_key
  end

  def transform_boolean(value)
    result = value ? 'Yes' : 'No'
  end

  def app_icons
    {
      facebook: '<i class="fa fa-facebook-square fa-2x"></i>',
      news: '<i class="fa fa-rss-square fa-2x"></i>',
      twitter: '<i class="fa fa-twitter-square fa-2x"></i>',
      github: '<i class="fa fa-github-square fa-2x" aria-hidden="true"></i>',
      info: '<i class="fa fa-info-circle"></i>',
      pinterest: '<i class="fa fa-pinterest-square fa-2x" aria-hidden="true"></i>',
      instagram: '<i class="fa fa-instagram fa-2x"></i>'
    }
  end

  def social_links
    {
      facebook: 'https://www.facebook.com/freeukgen',
      news: 'https://www.freeukgenealogy.org.uk/news/',
      twitter: 'https://www.twitter.com/freeukgen',
      github: 'https://github.com/FreeUKGen/MyopicVicar/',
      pinterest: 'https://www.pinterest.co.uk/FreeUKGenealogy/',
      instagram: 'https://www.instagram.com/freeukgenealogy/'
    }
  end

  def html_options
    {target: '_blank', rel: 'noreferrer'}
  end

  def app_icons2
    {
      facebook: '<i class="fa fa-facebook-square fa-3x" title="facebook"></i>
      <span class="accessibility">facebook</span>',
      news: '<i class="fa fa-rss-square fa-3x" title="news"></i>
      <span class="accessibility">FreeUKGenealogy News</span>',
      twitter: '<i class="fa fa-twitter-square fa-3x" title="twitter"></i>
      <span class="accessibility">twitter</span>',
      pinterest: '<i class="fa fa-pinterest-square fa-3x" title="pinterest"></i>
      <span class="accessibility">pinterest</span>',
      instagram: '<i class="fa fa-instagram fa-3x" title="instagram"></i>
      <span class="accessibility">instagram</span>'

    }
  end

  def html_options2
    { rel: 'noreferrer' }
  end

  def html_options_freereg_icon
    { class: 'icon__freereg', rel: 'noreferrer' }
  end

  def html_options_freecen_icon
    { class: 'icon__freecen', rel: 'noreferrer' }
  end

  def html_options_freebmd_icon
    { class: 'icon__freebmd', rel: 'noreferrer' }
  end

  def html_options_freeukgen_icon
    { class: 'c-subfooter-1__fug-nav icon__freeukgen__project--light',
      rel: 'noreferrer' }
  end

  def helpful_anchors
    {
      cookiePolicy: 'Cookie Policy',
      privacyNotice: 'Privacy Notice
      <span class="accessibility">Opens in new window</span>',
      termAndConditions: 'Terms and Conditions',
      contactUs: 'Contact Us',
      donation: 'Make a donation to cover our operating costs
      <span class="accessibility">Opens in new window</span>',
      fugNews: 'News about Free UK Genealogy
      <span class="accessibility">Opens in new window</span>',
      freeregIcon: '<span class="accessibility">FreeREG</span>',
      freecenIcon: '<span class="accessibility">FreeCEN</span>',
      freebmdIcon: '<span class="accessibility">FreeBMD</span>',
      freebmdAccuracy: 'accuracy or completeness',
      freeukgenIcon: '<span class="accessibility">FreeUKGenealogy</span>',
      statistics: 'Statistics'
    }
  end

  def helpful_links
    {
      cookiePolicy: '/cms/about/cookie-policy',
      privacyNotice: 'https://drive.google.com/file/d/10r_c-5d9DDces-OUX7D4UJJKGNIhu8sV/view?usp=sharing',
      termAndConditions: '/cms/terms-and-conditions',
      contactUs: contact_us_path,
      donation: 'https://www.freeukgenealogy.org.uk/help-us-keep-history-free',
      fugNews: 'https://www.freeukgenealogy.org.uk/news/',
      freereg: 'https://www.freereg.org.uk/',
      freecen: 'https://www.freecen.org.uk/',
      freebmd: 'https://www.freebmd.org.uk/',
      freebmdAccuracy: '/cms/help#Accuracy',
      freeukgen: 'http://www.freeukgenealogy.org.uk/',
      freeregStat: 'https://www.freereg.org.uk/freereg_contents/new?locale=en',
      #freecenStat: 'https://www.freecen.org.uk/freecen_coverage?locale=en',
      freecenStat: 'https://www.freecen.org.uk/freecen2_contents?locale=en',
      freebmdStat: 'https://www.freebmd.org.uk/progress.shtml'
    }
  end

  def contact_us_path
    case appname_downcase
    when "freereg"
      path = '/cms/help/frequently-asked-questions-researchers?'
    when "freecen"
      path = '/contacts/new'
    end
    path
  end

  def fullwidth_adsense_freereg
    banner = <<-HTML
    <script src="//pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
    <ins class="adsbygoogle adSenseBanner"
    style="display:inline-block;width:728px;height:90px"
    data-ad-client="#{data_ad_client}"
    data-ad-slot="#{data_ad_slot_header}">
    </ins>
    <script type="text/javascript">
    (adsbygoogle = window.adsbygoogle || []).push({});
    </script>
    HTML
    if Rails.env.development?
      banner = <<-HTML
      <img src="http://dummyimage.com/728x90/000/fff/?text=banner+ad" alt='Banner add'>
      HTML
    end
    banner.html_safe
  end

  def fullwidth_adsense_freecen
    banner = <<-HTML
    <script async src="//pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
    <!-- FreeCEN2 Transcriber Registration (Responsive) -->
    <ins class="adsbygoogle adSenseBanner"
    style="display:inline-block;width:728px;height:90px"
    data-ad-client="#{data_ad_client}"
    data-ad-slot="#{data_ad_slot_fullwidth}">
    </ins>
    <script type="text/javascript">
    (adsbygoogle = window.adsbygoogle || []).push({});
    </script>
    HTML
    if Rails.env.development?
      banner = <<-HTML
      <img src="http://dummyimage.com/728x90/000/fff/?text=banner+ad" alt='Banner add'>
      HTML
    end
    banner.html_safe
  end

  def adsence_right_side_banner_gdpr
    banner = <<-HTML
    <script src="//pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
    <ins class="adsbygoogle float--right"
    style="display:inline-block;width:300px;height:600px"
    data-ad-client = "#{data_ad_client}"
    data-ad-slot = "#{app_advert['data_ad_slot_side']}">
    </ins>
    <script type="text/javascript">
    (adsbygoogle = window.adsbygoogle || []).push({});
    </script>
    HTML
    if Rails.env.development?
      banner = <<-HTML
      <img src="http://dummyimage.com/120x600/000/fff?text=banner+ad">
      HTML
    end
    banner.html_safe
  end

  def adsence_right_side_banner_non_gdpr
    banner = <<-HTML
    <script src="//pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
    <ins class="adsbygoogle float--right"
    style="display:inline-block;width:300px;height:600px"
    data-ad-client = "#{data_ad_client}"
    data-ad-slot = "#{app_advert['data_ad_slot_side']}">
    </ins>
    <script type="text/javascript">
    (adsbygoogle=window.adsbygoogle||[]).pauseAdRequests=1;
    window.update_personalized_side_adverts = function (preference) {
      if(preference == 'accept') {
          (adsbygoogle = window.adsbygoogle || []).requestNonPersonalizedAds=0;
        } else if(preference == 'deny') {
          (adsbygoogle = window.adsbygoogle || []).requestNonPersonalizedAds=1;
        }
        };
        (adsbygoogle=window.adsbygoogle||[]).pauseAdRequests=0;
        </script>
        <script type="text/javascript">
        (adsbygoogle = window.adsbygoogle || []).push({});
        </script>
        HTML
        if Rails.env.development?
          banner = <<-HTML
          <img src="http://dummyimage.com/120x600/000/fff?text=banner+ad">
          HTML
        end
        banner.html_safe
      end

      def adsence_right_side_banner
        if GdprCountries::FOLLOWED_COUNTRIES.include?(user_location)
          bannner = adsence_right_side_banner_gdpr
        else
          banner = adsence_right_side_banner_non_gdpr
        end
        banner
      end

      def google_advert
        @data_ad_slot = current_page?(freecen_coverage_path) ? data_ad_slot_coverage : data_ad_slot_google_advert
        banner = <<-HTML
        <script async src="//pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
        <!-- Responsive ad -->
        <ins class="adsbygoogle adSenseBanner"
        style="display:inline-block;width:728px;height:90px"
        data-ad-client="#{data_ad_client}"
        data-ad-slot= "#{@data_ad_slot}">
        </ins>
        <script type="text/javascript">
        (adsbygoogle = window.adsbygoogle || []).push({});
        </script>
        HTML
        if Rails.env.development?
          banner = <<-HTML
          <img src="http://dummyimage.com/728x90/000/fff/?text=banner+ad" alt='Banner add'>
          HTML
        end
        banner.html_safe
      end

      def user_location
        request.location.present? ? request.location.country : ""
      end

      def banner_header
        logger.warn(user_location.inspect)
        if GdprCountries::FOLLOWED_COUNTRIES.include?(user_location)
          bannner = banner_header_gdpr
        else
          banner = banner_header_non_gdpr
        end
        banner
      end


      def banner_header_non_gdpr
        banner = <<-HTML
        <script src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
        <ins class="adsbygoogle adSenseBanner"
        style="display:inline-block;width:728px;height:90px"
        data-ad-client = "#{data_ad_client}"
        data-ad-slot = "#{data_ad_slot_header}">
        </ins>
        <script>
        (adsbygoogle=window.adsbygoogle||[]).pauseAdRequests=1;
        window.update_personalized_header_adverts = function (preference) {
          if(preference == 'accept') {
              (adsbygoogle = window.adsbygoogle || []).requestNonPersonalizedAds=0;
            } else if(preference == 'deny') {
              (adsbygoogle = window.adsbygoogle || []).requestNonPersonalizedAds=1;
            }
            };
            (adsbygoogle=window.adsbygoogle||[]).pauseAdRequests=0;
            </script>
            <script type="text/javascript">
            (adsbygoogle = window.adsbygoogle || []).push({});
            </script>
            HTML
            if Rails.env.development?
              banner = <<-HTML
              <img src="http://dummyimage.com/728x90/000/fff/?text=banner+ad" alt='Banner add'>
              HTML
            end
            banner.html_safe
          end

          def banner_header_gdpr
            banner = <<-HTML
            <script src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
            <ins class="adsbygoogle adSenseBanner"
            style="display:inline-block;width:728px;height:90px"
            data-ad-client = "#{data_ad_client}"
            data-ad-slot = "#{data_ad_slot_header}">
            </ins>
            <script type="text/javascript">
            (adsbygoogle = window.adsbygoogle || []).push({});
            </script>
            HTML
            if Rails.env.development?
              banner = <<-HTML
              <img src="http://dummyimage.com/728x90/000/fff/?text=banner+ad" alt='Banner add'>
              HTML
            end
            banner.html_safe
          end

          def side_banners
            banner = <<-HTML
            <script src="//pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
            <ins class="adsbygoogle adSenseBanner"
            style="display:inline-block;width:120px;height:600px"
            data-ad-client = "#{data_ad_client}"
            data-ad-slot = "#{app_advert['data_ad_slot_side']}">
            </ins>
            <script type="text/javascript">
            (adsbygoogle = window.adsbygoogle || []).push({});
            </script>
            HTML
            if Rails.env.development?
              banner = <<-HTML
              <img src="http://dummyimage.com/120x600/000/fff?text=banner+ad">
              HTML
            end
            banner.html_safe
          end

          def banner_header_freereg
            banner = <<-HTML
            <script src="//pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
            <script type="text/javascript">
            (adsbygoogle=window.adsbygoogle||[]).pauseAdRequests=1;
            window.update_page_level_adverts_consent = function (preference) {
              if(preference == 'accept') {
                  (adsbygoogle = window.adsbygoogle || []).requestNonPersonalizedAds=0;
                } else if(preference == 'deny') {
                  (adsbygoogle = window.adsbygoogle || []).requestNonPersonalizedAds=1;
                }
                };
                (adsbygoogle=window.adsbygoogle||[]).pauseAdRequests=0;
                </script>
                <script type="text/javascript">
                //Google Adsense
                (adsbygoogle = window.adsbygoogle || []).push({
                                                                google_ad_client: "#{data_ad_client}",
                                                                enable_page_level_ads: true
                });
                </script>
                HTML
                banner.html_safe
              end

              def side_banners_large
                banner = <<-HTML
                <script src="//pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
                <ins class="adsbygoogle adSenseBanner"
                style="display:inline-block;width:300px;height:600px"
                data-ad-client = "#{data_ad_client}"
                data-ad-slot = "#{app_advert['side_banners_large_slot']}">
                </ins>
                <script type="text/javascript">
                (adsbygoogle = window.adsbygoogle || []).push({});
                </script>
                HTML
                if Rails.env.development?
                  banner = <<-HTML
                  <img src="https://dummyimage.com/300x600/000/fff">
                  HTML
                end
                banner.html_safe
              end

              def side_banners_square
                banner = <<-HTML
                <script src="//pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
                <ins class="adsbygoogle adSenseBanner"
                style="display:inline-block;width:336px;height:280px"
                data-ad-client = "#{data_ad_client}"
                data-ad-slot = "#{app_advert['side_banners_square_slot']}">
                </ins>
                <script type="text/javascript">
                (adsbygoogle = window.adsbygoogle || []).push({});
                </script>
                HTML
                if Rails.env.development?
                  banner = <<-HTML
                  <img src="http://dummyimage.com/300x250/000/fff?text=banner+ad">
                  HTML
                end
                banner.html_safe
              end
              end
