crumb :root do
  link "Your Actions:", new_manage_resource_path
end
# Profile 
crumb :userid_detail do |userid_detail|
   link "Profile:#{userid_detail.userid}", userid_detail
   if session[:my_own]
    parent :root
   else
    if session[:role] == "syndicate_coordinator"  || session[:role] == "county_coordinator" || 
      session[:role] == "country_coordinator" || session[:role] == "volunteer_coordinator" || 
      session[:role] == "system_administrator" 
     parent :userid_details_listing, session[:syndicate] 
    end
   end
end
crumb :edit_userid_detail do |userid_detail|
   link "Edit Profile:#{userid_detail.userid}", userid_detail
   parent :userid_detail, userid_detail
end
crumb :disable_userid_detail do |userid_detail|
   link "Disable Profile:#{userid_detail.userid}", userid_detail
   parent :userid_detail, userid_detail
end

#File
crumb :my_options do 
   link "My Files Options", my_own_freereg1_csv_file_path
end

crumb :files do  
   link "List of Files", freereg1_csv_files_path
   if session[:my_own]
    parent :my_options, my_own_freereg1_csv_file_path
   else
    if session[:role] == "county_coordinator" || session[:role] == "data_manager" 
     parent :county_options, session[:county]
    end
    if session[:role] == "syndicate_coordinator" || session[:role] == "volunteer_coordinator"
     parent :userid_details_listing, session[:syndicate] 
    end
    if session[:role] == "system_administrator" || session[:role] == "technical"
      parent :root
    end
   end
 end
crumb :show_file do |file|
   link "Showing File", freereg1_csv_file_path(file)
   parent :files #parent :my_options, my_own_freereg1_csv_file_path
end
crumb :edit_file do |file|
   link "Editing File", edit_freereg1_csv_file_path(file)
   parent :show_file, file 
end
crumb :relocate_file do |file|
   link "Relocating File", freereg1_csv_file_path(file)
   parent :show_file, file 
end
crumb :show_records do |file|
   link "Listing the Records", freereg1_csv_entries_path
   parent :show_file, file 
end
crumb :new_record do |file|
   link "Adding a Record", new_freereg1_csv_entry_path
   parent :show_records, file 
end
crumb :error_records do |file|
   link "Listing Errors", error_freereg1_csv_entry_path
   parent :show_records, file 
end


#manage county
crumb :county_options do |county|
   link "County Options(#{county})", select_action_manage_counties_path("?county=#{county}")
   parent :root
end
crumb :county_places do |county,place|
   if place.nil?
   link "Places", places_path
   else
   link "Places", places_path(:anchor => "#{place.id}")
   end
    parent :county_options, county
end
crumb :show_place do |county,place|
   link "Place Information", place_path(place)
    parent :county_places, county, place
end
crumb :edit_place do |county,place|
    link "Edit Place Information", edit_place_path(place)
    parent :show_place, county, place
end
crumb :create_place do |county,place|
   link "Create New Place", new_place_path
   parent :county_places, county, place
end
crumb :rename_place do |county,place|
   link "Rename Place", rename_place_path
   parent :county_places, county, place
end
crumb :relocate_place do |county,place|
   link "Relocate Place", relocate_place_path
   parent :county_places, county, place
end
crumb :show_church do |county,place,church|
   link "Church Information", church_path(church)
   parent :show_place, county, place
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
   link "Register Information", register_path(register)
   parent :show_church, county, place,church
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
crumb :userid_details_listing do |syndicate|
   link "Syndicate Listing", userid_details_path
   parent :syndicate_options, syndicate
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