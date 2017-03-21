crumb :root do
  link "Your Actions:", main_app.new_manage_resource_path
end
#
crumb :my_own_userid_detail do |userid_detail|
  link "Profile:#{userid_detail.userid}", my_own_userid_detail_path
  parent :root
end

crumb :edit_userid_detail do |syndicate, userid_detail|
  link "Edit Profile:#{userid_detail.userid}", userid_detail_path
  if session[:my_own]
    parent :my_own_userid_detail, userid_detail
  else
    parent :userid_detail, syndicate, userid_detail
  end
end
crumb :disable_userid_detail do |userid_detail|
  link "Disable Profile:#{userid_detail.userid}", userid_detail_path
  parent :userid_detail, session[:syndicate],userid_detail
end
crumb :create_userid_detail do |userid_detail|
  link "Create New Profile", new_userid_detail_path

  if session[:role] == "syndicate_coordinator"  || session[:role] == "county_coordinator" ||
      session[:role] == "country_coordinator" || session[:role] == "volunteer_coordinator" ||
      session[:role] == "data_manager"

    parent :userid_details_listing, session[:syndicate],userid_detail
  end
  if  session[:role] == "system_administrator" || session[:role] == "technical"

    parent :userid_details_listing, "all" ,userid_detail
  end
end



#File
crumb :my_own_files do
  link "Your Batches", my_own_freereg1_csv_file_path
end

crumb :files  do |file|
  if session[:my_own].present?
    link "Your Batches", my_own_freereg1_csv_file_path
    parent :root
  else
    if file.nil?
      link "List of Batches", freereg1_csv_files_path
    else
      link "List of Batches", freereg1_csv_files_path(:anchor => "#{file.id}",  :page => "#{session[:current_page]}")

    end
    case
    when session[:county].present? &&
        (session[:role] == "county_coordinator"  || session[:role] == "system_administrator" || session[:role] == "technical" || session[:role] == "data_manager" )
      if  session[:place_name].present?
        place = Place.where(:chapman_code => session[:chapman_code], :place_name => session[:place_name]).first
        unless place.nil?
          parent :show_place, session[:county], place
        else
          parent :county_options, session[:county]
        end
      else
        parent :county_options, session[:county]
      end
    when session[:role] == "volunteer_coordinator" || session[:role] == "syndicate_coordinator"
      parent :userid_details_listing, session[:syndicate]
    when session[:syndicate].present? && (session[:role] == "county_coordinator" || session[:role] == "data_manager" ||session[:role] == "system_administrator" || session[:role] == "technical")
      unless  session[:userid_id].nil?
        parent :userid_detail, session[:syndicate], UseridDetail.find(session[:userid_id])
      else
        parent :syndicate_options, session[:syndicate]
      end
    when session[:role] == "system_administrator" || session[:role] == "technical"
      parent :regmanager_userid_options
    else

    end
  end
end
crumb :show_file do |file|
  link "Batch Information", freereg1_csv_file_path(file)
  if session[:my_own]
    parent :files, file
  else
    if session[:register_id].present? && session[:county].present? && session[:place_id].present? && session[:church_id].present? && session[:register_id].present?
      place = Place.id(session[:place_id]).first
      church = Church.id(session[:church_id]).first
      register = Register.id(session[:register_id]).first
      if place.present? && church.present? && register.present?
        parent :show_register, session[:county], place, church, register
      end
    else
      parent :files, file
    end
  end
end
crumb :edit_file do |file|
  link "Editing Batch Information", edit_freereg1_csv_file_path(file)

  parent :show_file, file
end
crumb :relocate_file do |file|
  link "Relocating Batch", freereg1_csv_file_path(file)
  parent :show_file, file
end
crumb :waiting do |file|
  link "Files waiting to be processed"
  if session[:my_own]
    parent :my_own_files
  else
    parent :files, file
  end
end
crumb :change_userid do |file|
  link "Changing owner"
  parent :show_file, file
end
crumb :select_file do |user|
  link "Selecting file"
  if session[:my_own]
    parent :my_own_files
  else
    parent :files, file
  end
end



#record or entry
crumb :show_records do |file|
  link "List of Records", freereg1_csv_entries_path(:anchor => "#{file.id}")
  parent :show_file, file
end
crumb :new_record do |entry,file|
  link "Create New Record", new_freereg1_csv_entry_path
  parent :show_records, file
end
crumb :error_records do |file|
  link "List of Errors", error_freereg1_csv_file_path(file)
  parent :show_file, file
end
crumb :show_record do |entry,file|
  link "Record Contents", freereg1_csv_entry_path(entry)
  parent :show_records, file
end
crumb :edit_record do |entry,file|
  link "Edit Record", edit_freereg1_csv_entry_path(entry)
  parent :show_record, entry,file
end
crumb :correct_error_record do |entry,file|
  link "Correct Error Record", error_freereg1_csv_entry_path(entry._id)
  parent :error_records, file
end


#manage county
crumb :county_options do |county|
  link "County Options(#{county})", select_action_manage_counties_path(:county => "#{county}")
  parent :root
end
crumb :place_range_options do |county,active|
  if session[:active_place]
    link "Range Selection", selection_active_manage_counties_path(:option =>'Work with Active Places')
  else
    link "Range Selection", selection_all_manage_counties_path(:option =>'Work with All Places')
  end
  parent :county_options, county
end

crumb :places do |county,place|
  case
  when session[:character].present?
    link "Places", place_range_manage_counties_path
  when place.blank?
    link "Places", places_path
  when place.present?
    link "Places", places_path(:anchor => "session[place.id]")
  end
  if session[:character].present?
    parent :place_range_options, county,session[:active]
  else
    parent :county_options, county
  end
end

crumb :places_range do |county,place|
  link "Places", places_path
  parent :place_range_options, county,session[:active]
end

crumb :show_place do |county,place|
  link "Place Information", place_path(place)
  case
  when session[:select_place] || place.blank?
    parent :county_options, session[:county] if session[:county].present?
    parent :syndicate_options, session[:syndicate] if session[:syndicate].present?
  when place.present?
    parent :places, county, place
  end

end
crumb :edit_place do |county,place|
  link "Edit Place Information", edit_place_path(place)
  parent :show_place, county, place
end
crumb :create_place do |county,place|
  link "Create New Place", new_place_path
  parent :places, county, place
end
crumb :rename_place do |county,place|
  link "Rename Place", rename_place_path
  parent :places, county, place
end
crumb :relocate_place do |county,place|
  link "Relocate Place", relocate_place_path
  parent :places, county, place
end
crumb :show_church do |county,place,church|
  if church.present?
    link "Church Information", church_path(church)
    parent :show_place, county, place
  else
    parent :county_options, session[:county] if session[:county].present?
    parent :syndicate_options, session[:syndicate] if session[:syndicate].present?
  end
end
crumb :edit_church do |county,place,church|
  link "Edit Church Information", edit_church_path(church)
  parent :show_church, county, place, church
end
crumb :create_church do |county,place|
  link "Create New Church", new_church_path
  parent :show_place, county, place
end
crumb :rename_church do |county,place,church|
  link "Rename Church", rename_church_path
  parent :show_church, county, place, church
end
crumb :relocate_church do |county,place,church|
  link "Relocate Church", relocate_church_path
  parent :show_church, county, place, church
end
crumb :show_register do |county,place,church,register|
  if register.present?
    link "Register Information", register_path(register)
    parent :show_church, county, place,church
  else
    parent :county_options, session[:county] if session[:county].present?
    parent :syndicate_options, session[:syndicate] if session[:syndicate].present?
  end
end
crumb :edit_register do |county,place,church,register|
  link "Edit Register Information", edit_register_path(register)
  parent :show_register, county, place, church, register
end
crumb :create_register do |county,place,church|
  link "Create New Register", new_register_path
  parent :show_church, county, place, church
end
crumb :rename_register do |county,place,church,register|
  link "Rename Register", rename_register_path
  parent :show_register, county, place, church, register
end

#manage syndicate
crumb :syndicate_options do |syndicate|
  link "Syndicate Options(#{syndicate})", select_action_manage_syndicates_path("?syndicate=#{syndicate}")
  parent :root
end

crumb :userid_details_listing do |syndicate,user|
  case
  when user.nil?
    link "Syndicate Listing", userid_details_path
  when !user.nil?
    unless session[:manager].nil?
      link "Syndicate Listing", userid_details_path(:anchor => "#{user.id}", :page => "#{session[:manager]}")
    else
      link "Syndicate Listing", userid_details_path(:anchor => "#{user.id}")
    end
  end
  case
  when !session[:syndicate].nil? && (session[:role] == "county_coordinator" ||
                                     session[:role] == "system_administrator" || session[:role] == "technical" ||
                                     session[:role] == "volunteer_coordinator" || session[:role] == "syndicate_coordinator" )
    parent :syndicate_options, session[:syndicate]
  when session[:role] == "system_administrator" || session[:role] == "technical"
    parent :regmanager_userid_options
  else
    parent :syndicate_options, syndicate
  end
end
crumb :syndicate_waiting do |syndicate|
  link "Files waiting to be processed"
  parent :syndicate_options,syndicate
end


#Profile
crumb :userid_detail do |syndicate,userid_detail|
  link "Profile:#{userid_detail.userid}", userid_detail_path(userid_detail.id)
  if session[:my_own]
    parent :root
  else
    if  session[:edit_userid]
      syndicate = session[:syndicate]
      syndicate = "all"  if  session[:role] == "system_administrator" || session[:role] == "technical"
      parent :userid_details_listing, syndicate,userid_detail
    else
      parent :coordinator_userid_options
    end
  end
end



#manage userids
crumb :regmanager_userid_options do
  link "Userid Management Options", options_userid_details_path
  parent :root
end
crumb :coordinator_userid_options do
  link "Profile Display Selection", display_userid_details_path
  parent :root
end
crumb :rename_userid do |user|
  link "Rename Userid", rename_userid_details_path
  parent :userid_detail, user.syndicate,user
end
crumb :role_listing do
  link "Role Listing"
  parent :regmanager_userid_options
end
crumb :incomplete_registrations do
  link 'Incomplete Registration Listing'
  parent :regmanager_userid_options, incomplete_registrations_userid_details_path
end


#Physical Files

crumb :physical_files_options do
  link "Physical Files Options", select_action_physical_files_path
  parent :root
end
crumb :physical_files do |type|
  link "Listing of Physical Files", physical_files_path
  case
  when Syndicate.is_syndicate?(type)
    parent :syndicate_options, type
  when County.is_county?(type)
    parent :county_options, type
  else
    parent :physical_files_options
  end
end
crumb :show_physical_files do |physical_file|
  link "Show a Physical File", physical_file_path(physical_file)
  parent :physical_files
end

#csvfiles
crumb :new_csvfile do |csvfile|
  link "Upload New File", new_csvfile_path
  case
  when session[:my_own]
    parent :files, nil
  when session[:county]
    parent :county_options, session[:county]
  when session[:syndicate]
    parent :syndicate_options, session[:syndicate]
  end
end
crumb :edit_csvfile do |csvfile,file|
  link "Replace File", edit_csvfile_path
  case
  when session[:my_own]
    parent :files, file
  when session[:county]
    parent :files, file
    #parent :county_options, session[:county]
  when session[:syndicate]
    parent :syndicate_options, session[:syndicate]
  end
end
#Feedback

crumb :feedback_form do
  parent :root
end
crumb :feedbacks do
  link "Feedbacks", feedbacks_path
  parent :root
end
crumb :show_feedback do |feedback|
  link "Show Feedback", feedback_path(feedback)
  parent :feedbacks
end
crumb :edit_feedback do |feedback|
  link "Edit Feedback", edit_feedback_path(feedback)
  parent :show_feedback, feedback
end
#manage contacts
crumb :contacts do
  link "Contacts", contacts_path
  parent :root
end
#manage contacts
crumb :show_contact do |contact|
  link "Show Contact", contact_path(contact)
  parent :contacts
end
crumb :edit_contact do |contact|
  link "Edit Contact", edit_contact_path(contact)
  parent :show_contact, contact
end
crumb :messages do
  link "Messages", messages_path
  parent :root
end
crumb :show_message do |message|
  link "Show Message", message_path(message)
  parent :messages
end
crumb :edit_message do |message|
  link "Edit Message", edit_message_path(message)
  parent :show_message, message
end
crumb :create_message do |message|
  link "Create Message", new_message_path(message)
  parent :messages
end
crumb :send_message do |message|
  link "Send Message", send_message_messages_path(message)
  parent :show_message, message
end
crumb :denominations do
  link "Denominations", denominations_path
  parent :root
end
crumb :show_denomination do |denomination|
  link "Show Denomination", denomination_path(denomination)
  parent :denominations
end
crumb :edit_denomination do |denomination|
  link "Edit Denomination", edit_denomination_path(denomination)
  parent :show_denomination, denomination
end
crumb :create_denomination do |denomination|
  link "Create Denomination", new_denomination_path(denomination)
  parent :denominations
end
crumb :select_attic_files do
  link "Select Userid", select_attic_files_path
  parent :root
end
crumb :show_attic_files do |user|
  link "Listing of Attic Files", attic_files_path(user)
  parent :select_attic_files
end
crumb :countries do
  link "Countries", countries_path
  parent :root
end
crumb :show_countries do |country|
  link "Show Country", country_path(country)
  parent :countries
end
crumb :edit_country do |country|
  link "Edit Country", edit_country_path(country)
  parent :show_countries, country
end
crumb :counties do
  link "Counties", counties_path
  parent :root
end
crumb :show_counties do |county|
  link "Show County", county_path(county)
  parent :counties
end
crumb :edit_county do |county|
  link "Edit County", edit_county_path(county)
  parent :show_counties, county
end
crumb :syndicates do
  link "Syndicates", syndicates_path
  parent :root
end
crumb :show_syndicate do |syndicate|
  link "Show Syndicate", syndicate_path(syndicate)
  parent :syndicates
end
crumb :edit_syndicate do |syndicate|
  link "Edit Syndicate", edit_syndicate_path(syndicate)
  parent :show_syndicate, syndicate
end
crumb :create_syndicate do |syndicate|
  link "Create Syndicate", new_syndicate_path(syndicate)
  parent :syndicates
end


# crumb :projects do
#   link "Projects", projects_path
# end

# crumb :project do |project|
#   link project.name, project_path(project)
#   parent :projects
# end

# crumb :project_issues do |project|
#   link "Issues", project_issues_path(project)
#   parent :project, project
# end

# crumb :issue do |issue|
#   link issue.title, issue_path(issue)
#   parent :project_issues, issue.project
# end

# If you want to split your breadcrumbs configuration over multiple files, you
# can create a folder named `config/breadcrumbs` and put your configuration
# files there. All *.rb files (e.g. `frontend.rb` or `products.rb`) in that
# folder are loaded and reloaded automatically when you change them, just like
# this file (`config/breadcrumbs.rb`).
