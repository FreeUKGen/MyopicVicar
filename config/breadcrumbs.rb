crumb :root do
  link "Your Actions:", main_app.new_manage_resource_path
end
#
crumb :my_own_userid_detail do |userid_detail|
   link "Profile:#{userid_detail.userid}", my_own_userid_detail_path
    parent :root
end

crumb :edit_userid_detail do |userid_detail|
   link "Edit Profile:#{userid_detail.userid}", userid_detail_path
   if session[:my_own]
     parent :my_own_userid_detail, userid_detail
   else
     parent :userid_detail, userid_detail
 end
end
crumb :disable_userid_detail do |userid_detail|
   link "Disable Profile:#{userid_detail.userid}", userid_detail_path
   parent :userid_detail, userid_detail
end
crumb :create_userid_detail do |userid_detail|
   link "Create New Profile", new_userid_detail_path
   if  session[:role] == "system_administrator" 
     parent :regmanager_userid_options
   else
    parent :userid_detail, userid_detail
   end
end

#File
crumb :my_options do 
   link "My Batches Options", my_own_freereg1_csv_file_path
end

crumb :files  do |file|
  if file.nil?
    link "List of Batches", freereg1_csv_files_path
  else
p  
   link "List of Batches", freereg1_csv_files_path(:anchor => "#{file.id}")
  end
   case
   when session[:my_own]
    parent :my_options, my_own_freereg1_csv_file_path
   when session[:role] == "data_manager"
     parent :county_options, session[:county]

   when !session[:county].nil? && (session[:role] == "county_coordinator"  || session[:role] == "system_administrator" || session[:role] == "technical")   
     
     unless  session[:place_name].nil?
     parent :show_place, session[:county], get_place(session[:chapman_code],session[:place_name])
   else
    parent :county_options, session[:county]
   end
   when session[:role] == "volunteer_coordinator" || session[:role] == "syndicate_coordinator" 
     parent :userid_details_listing, session[:syndicate] 
   when !session[:syndicate].nil? && (session[:role] == "county_coordinator" || session[:role] == "system_administrator" || session[:role] == "technical") 
      parent :userid_details_listing, session[:syndicate] 
   when session[:role] == "system_administrator" || session[:role] == "technical"
       parent :regmanager_userid_options
   end

 end
crumb :show_file do |file|
   link "Batch Information", freereg1_csv_file_path(file)
   parent :files, file #parent :my_options, my_own_freereg1_csv_file_path
end
crumb :edit_file do |file|
   link "Editing Batch Information", edit_freereg1_csv_file_path(file)
   parent :show_file, file 
end
crumb :relocate_file do |file|
   link "Relocating Batch", freereg1_csv_file_path(file)
   parent :show_file, file 
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

 #Profile 
crumb :userid_detail do |userid_detail|
   link "Profile:#{userid_detail.userid}", userid_detail_path
   if session[:my_own]
    parent :root
   else
    if session[:role] == "syndicate_coordinator"  || session[:role] == "county_coordinator" || 
       session[:role] == "country_coordinator" || session[:role] == "volunteer_coordinator"  
     parent :userid_details_listing, session[:syndicate] 
    end
    if  session[:role] == "system_administrator" || session[:role] == "technical"
      parent :userid_details_listing, "all" 
    end
   end
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
#manage userids
crumb :regmanager_userid_options do 
   link "Userid Management Options", options_userid_details_path
   parent :root
end
crumb :rename_userid do |user|
   link "Rename Userid", rename_userid_details_path
   parent :userid_detail, user
end

#Physical Files

crumb :physical_files_options do 
   link "Physical Files Options", select_action_physical_files_path
   parent :root
end
crumb :physical_files do 
   link "Listing of Physical Files", physical_files_path
   parent :physical_files_options
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