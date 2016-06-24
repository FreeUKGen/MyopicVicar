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
    @userid = session[:userid]
    @user_id = session[:user_id]
    @first_name = session[:first_name]
    @manager = session[:manager]
    @roles = session[:role]
    @user = UseridDetail.where(:userid => session[:userid]).first
    @roles = UseridRole::OPTIONS.fetch(session[:role])
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

    display_map["Start Year"] = search_query.start_year if search_query.start_year
    display_map["End Year"] = search_query.end_year if search_query.end_year

    counties = search_query.chapman_codes.map{|code| ChapmanCode::name_from_code(code)}.join(" or ")
    display_map["Counties"] = counties if search_query.chapman_codes.size > 1
    display_map["County"] = counties if search_query.chapman_codes.size == 1

    if search_query.places.size > 0
      place = search_query.places.first.place_name
      if search_query.all_radius_places.size > 0
        place <<
        " (including #{search_query.all_radius_places.size} additional places within
          #{search_query.all_radius_places.last.geo_near_distance.round(1)}
          #{Place::MeasurementSystem::system_to_units(Place::MeasurementSystem::ENGLISH)} )"
      end
      display_map["Place"] = place if search_query.places.size > 0
    end
    display_map["Include Family Members"] = "Yes" if search_query.inclusive

    display_map
  end

  def display_banner
    banner = <<-HTML
    <script async src="//pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
    <ins class="adsbygoogle"
    style="display:inline-block;width:728px;height:90px"
    data-ad-client="ca-pub-7825403497160061"
    data-ad-slot="3235467631"></ins>
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
    else
      content_for?(:title) ? "FreeReg" + ' | ' + content_for(:title) : "FreeReg"
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

end
