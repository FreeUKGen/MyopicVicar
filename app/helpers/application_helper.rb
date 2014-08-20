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

  # generate proper display for the search query, in display order
  def search_params_for_display(search_query)
    display_map = {}
    # name fields
    display_map["First Name"] = search_query.first_name if search_query.first_name
    display_map["Last Name"] = search_query.last_name if search_query.last_name
    display_map["Exact Match?"] = "Yes" unless search_query.fuzzy
    display_map["Record Type"] = RecordType::display_name(search_query.record_type)    

    display_map["Start Year"] = search_query.start_year if search_query.start_year 
    display_map["End Year"] = search_query.end_year if search_query.end_year

    counties = search_query.chapman_codes.map{|code| ChapmanCode::name_from_code(code)}.join(" or ")
    display_map["Counties"] = counties if search_query.chapman_codes.size > 1 
    display_map["County"] = counties if search_query.chapman_codes.size == 1 

    if search_query.places.size > 0
      place = search_query.places.first.place_name
      if search_query.all_radius_places.size > 0
        place << 
          " (including " + 
          search_query.all_radius_places.size + 
          " additional places within " + 
          search_query.all_radius_places.last.geo_near_distance +
          Place::MeasurementSystem::system_to_units(search_query.place_system) +
          ")"
      end
      display_map["Place"] = place if search_query.places.size > 0
    end    
    display_map["Include Family Members"] = "Yes" if search_query.inclusive
    
    display_map
  end

  
  def time_ago(time)
    delta_seconds = (Time.new - time).floor
    delta_minutes = (delta_seconds / 60).floor
    delta_hours = (delta_minutes / 60).floor
    delta_days = (delta_hours / 24).floor

    if delta_days > 1
      "#{delta_days} days ago"
    elsif delta_days == 1
      "1 day ago"
    elsif delta_hours > 1
      "#{delta_hours} hours ago"
    elsif delta_hours == 1
      "1 hour ago"
    elsif delta_minutes > 1
      "#{delta_minutes} minutes ago"
    elsif delta_minutes == 1
      "1 minute ago"
    elsif delta_seconds > 1
      "#{delta_seconds} seconds ago"
    else
      "1 second ago"
    end
  end
  
end
