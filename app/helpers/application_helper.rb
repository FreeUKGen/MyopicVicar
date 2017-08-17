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

  def get_user_info_from_userid
    @user = cookies.signed[:userid]
    unless @user.blank?
      @first_name = @user.person_forename
      @user_id = @user.id
      @userid = @user.id
      @manager = manager?(@user)
      @roles = UseridRole::OPTIONS.fetch(@user.person_role)
    end
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
    session_id = request.session["session_id"]
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
    session_id = request.session["session_id"]
    problem_page_url=request.env['REQUEST_URI']
    previous_page_url=request.env['HTTP_REFERER']
    feedback_type=Feedback::FeedbackType::ISSUE
    user_id = session[:userid]

    {  :feedback_time => problem_time,
       :session_id => session_id,
       :user_id => user_id,
       :problem_page_url => problem_page_url,
       :previous_page_url => previous_page_url,
       :feedback_type => feedback_type }
  end


  def freereg1_csv_file_for_display(freereg1_csv_file)
    display_map = {}
    display_map["Register Type"] = RegisterType.display_name(freereg1_csv_file.register.register_type)
    display_map["Record Type"] = RecordType::display_name(freereg1_csv_file.record_type)
    display_map["Oldest Entry"] = freereg1_csv_file.datemin
    display_map["Newest Entry"] = freereg1_csv_file.datemax
    display_map["File Name"] = freereg1_csv_file.file_name
    display_map["Transcriber Syndicate"] = freereg1_csv_file.transcriber_syndicate
    display_map["Comment #1"] = freereg1_csv_file.first_comment if freereg1_csv_file.first_comment
    display_map["Comment #2"] = freereg1_csv_file.second_comment if freereg1_csv_file.second_comment

    display_map
  end

  # generate proper display for the search query, in display order
  def search_params_for_display(search_query)
    display_map = {}
    # name fields
    display_map["First Name"] = search_query.first_name.upcase if search_query.first_name
    display_map["Last Name"] = search_query.last_name.upcase if search_query.last_name
    display_map["Exact Match?"] = "Yes" unless search_query.fuzzy
    display_map["Exact Match?"] = "No" if search_query.fuzzy

    display_map["Record Type"] = RecordType::display_name(search_query.record_type) if search_query.record_type
    display_map["Record Type"] = "All" if search_query.record_type.blank?

    display_map["Start Year"] = search_query.start_year if search_query.start_year
    display_map["End Year"] = search_query.end_year if search_query.end_year

    counties = search_query.chapman_codes.map{|code| ChapmanCode::name_from_code(code)}.join(" or ")
    display_map["Counties"] = counties if search_query.chapman_codes.size > 1
    display_map["County"] = counties if search_query.chapman_codes.size == 1
    search_query[:place_ids].present? ? search_query_places_size = search_query[:place_ids].length : search_query_places_size = 0
    if search_query_places_size > 0
      first_place = search_query[:place_ids][0]
      first_place = Place.find(first_place)
      place = first_place.place_name
      if search_query.all_radius_place_ids.length > 1
        last_place = search_query.all_radius_place_ids[-2]
        last_place = Place.find(last_place)
        additional = search_query.all_radius_place_ids.length - 1
        place <<
        " (including #{additional} additional places within
          #{geo_near_distance(first_place,last_place,Place::MeasurementSystem::ENGLISH).round(1)}
          #{Place::MeasurementSystem::system_to_units(Place::MeasurementSystem::ENGLISH)} )"
      end
      display_map["Place"] = place if search_query_places_size > 0
    end
    display_map["Include Family Members"] = "Yes" if search_query.inclusive
    display_map["Include Winesses"] = "Yes" if search_query.witness
    display_map
  end

  def geo_near_distance(first,last,units)
    dist = Geocoder::Calculations.distance_between([first.latitude, first.longitude],[ last.latitude, last.longitude], {:units => :mi}) if units == Place::MeasurementSystem::ENGLISH
    dist = Geocoder::Calculations.distance_between([first.latitude, first.longitude],[ last.latitude, last.longitude],{:units => :km}) if units == Place::MeasurementSystem::SI
    dist
  end

  def display_banner
    banner = <<-HTML
    <script async src="//pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
    <!-- banner 468x60, created 12/10/10 -->
    <ins class="adsbygoogle"
         style="display:inline-block;width:468px;height:60px"
         data-ad-client="ca-pub-7825403497160061"
         data-ad-slot="0816871891"></ins>
    <script>
    (adsbygoogle = window.adsbygoogle || []).push({});
    </script>
    HTML
    if Rails.env.development?
      banner = <<-HTML
      <img src="http://dummyimage.com/728x90/000/fff/?text=banner+ad">
      HTML
    end
    banner.html_safe
  end

  def title(title = nil)
    if title.present?
      content_for :title, title
    elsif content_for?(:title)
      title = content_for(:title) +  ' | ' + "FreeReg"

    elsif  page_title.present?
      title = page_title + ' | '  + "FreeReg"
    else
      title = "FreeReg"
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
    raise "Not a Valid Directory" unless valid_directory?

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
      directory = File.join(@output_directory, "")
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
    when nil, "nil" then nil
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
  def register_type(file)
    register_type = file.register_type
    if register_type.blank?
      register = get_register_object(file)
      register_type = RegisterType.display_name(register.register_type) unless register.blank?
      file.update_attribute(:register_type, register_type) unless register.blank?
    else
      register_type = RegisterType.display_name(register_type)
    end

    register_type
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
      value = "Y"
    else
      value = "N"
    end
    value
  end
  def locked_by_coordinator(file)
    if file.locked_by_coordinator
      value = "Y"
    else
      value = "N"
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

  
end
