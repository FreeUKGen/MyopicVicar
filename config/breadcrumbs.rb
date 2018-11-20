crumb :root do
  link 'Your Actions:', main_app.new_manage_resource_path
end
#
crumb :my_own_userid_detail do |userid_detail|
  link "Profile:#{userid_detail.userid}", my_own_userid_detail_path
  parent :root
end

crumb :edit_userid_detail do |syndicate, userid_detail, page_name|
  link "Edit Profile:#{userid_detail.userid}", userid_detail_path
  if session[:my_own]
    parent :my_own_userid_detail, userid_detail
  else
    parent :userid_detail, syndicate, userid_detail, page_name
  end
end
crumb :disable_userid_detail do |userid_detail|
  link "Disable Profile:#{userid_detail.userid}", userid_detail_path
  parent :userid_detail, session[:syndicate], userid_detail
end
crumb :create_userid_detail do |userid_detail|
  link 'Create New Profile', new_userid_detail_path

  if session[:role] == 'syndicate_coordinator' || session[:role] == 'county_coordinator' ||
      session[:role] == 'country_coordinator' || session[:role] == 'volunteer_coordinator' ||
      session[:role] == 'data_manager'

    parent :userid_details_listing, session[:syndicate], userid_detail
  end
  if session[:role] == 'system_administrator' || session[:role] == 'technical'

    parent :userid_details_listing, 'all', userid_detail
  end
end
#................................................File....................................................
crumb :my_own_files do
  link 'Your Batches', my_own_freereg1_csv_file_path
end

crumb :files do |file|
  if session[:my_own].present?
    link 'Your Batches', my_own_freereg1_csv_file_path
    parent :root
  else
    if file.nil?
      link 'List of Batches', freereg1_csv_files_path
    else
      link 'List of Batches', freereg1_csv_files_path(:anchor => "#{file.id}", :page => "#{session[:current_page]}")
    end
    case
    when session[:county].present? &&
        (session[:role] == 'county_coordinator' || session[:role] == 'system_administrator' || session[:role] == 'technical' || session[:role] == 'data_manager' )

      if session[:place_name].present?
        place = Place.where(:chapman_code => session[:chapman_code], :place_name => session[:place_name]).first
        unless place.nil?
          parent :show_place, session[:county], place
        else
          parent :county_options, session[:county]
        end
      else
        parent :county_options, session[:county]
      end
    when session[:role] == 'volunteer_coordinator' || session[:role] == 'syndicate_coordinator'
      parent :userid_details_listing, session[:syndicate]
    when session[:syndicate].present? && (session[:role] == 'county_coordinator' || session[:role] == 'data_manager' ||session[:role] == 'system_administrator' || session[:role] == 'technical')
      unless  session[:userid_id].nil?
        parent :userid_detail, session[:syndicate], UseridDetail.find(session[:userid_id])
      else
        parent :syndicate_options, session[:syndicate]
      end
    when session[:role] == 'system_administrator' || session[:role] == 'technical'
      parent :regmanager_userid_options
    else

    end
  end
end
crumb :show_file do |file|
  link 'Batch Information', freereg1_csv_file_path(file.id)
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

crumb :unique_names do |file|
  link 'Unique Names'
  parent :show_file, file
end

crumb :edit_file do |file|
  link 'Editing Batch Information', edit_freereg1_csv_file_path(file)

  parent :show_file, file
end
crumb :relocate_file do |file|
  link 'Relocating Batch', freereg1_csv_file_path(file)
  parent :show_file, file
end
crumb :waiting do |file|
  link 'Files waiting to be processed'
  if session[:my_own]
    parent :my_own_files
  else
    parent :files, file
  end
end
crumb :change_userid do |file|
  link 'Changing owner'
  parent :show_file, file
end
crumb :select_file do |user|
  link 'Selecting file'
  if session[:my_own]
    parent :my_own_files
  else
    parent :files, file
  end
end



#record or entry
crumb :show_records do |entry, file|
  if entry.nil?
    link 'List of Records', freereg1_csv_entries_path
  else
    link 'List of Records', freereg1_csv_entries_path(:anchor => "#{entry.id}")
  end
  parent :show_file, file
end
crumb :new_record do |entry, file|
  link 'Create New Record', new_freereg1_csv_entry_path
  parent :show_records, entry,file
end
crumb :error_records do |file|
  link 'List of Errors', error_freereg1_csv_file_path(file)
  parent :show_file, file
end
crumb :show_record do |entry, file|
  link 'Record Contents', freereg1_csv_entry_path(entry)
  parent :show_records, entry,file
end
crumb :edit_record do |entry, file|
  link 'Edit Record', edit_freereg1_csv_entry_path(entry)
  parent :show_record, entry,file
end
crumb :correct_error_record do |entry, file|
  link 'Correct Error Record', error_freereg1_csv_entry_path(entry._id)
  parent :error_records, file
end


#manage county
crumb :county_options do |county|
  link "County Options(#{county})", select_action_manage_counties_path(:county => "#{county}")
  parent :root
end
crumb :place_range_options do |county, active|
  if session[:active_place]
    link 'Range Selection', selection_active_manage_counties_path(:option =>'Work with Active Places')
  else
    link 'Range Selection', selection_all_manage_counties_path(:option =>'Work with All Places')
  end
  parent :county_options, county
end

crumb :places do |county, place|
  case
  when session[:character].present?
    link 'Places', place_range_manage_counties_path
  when place.blank?
    link 'Places', places_path
  when place.present?
    link 'Places', places_path(:anchor => 'session[place.id]')
  end
  if session[:character].present?
    parent :place_range_options, county,session[:active]
  else
    parent :county_options, county
  end
end

crumb :places_range do |county, place|
  link 'Places', places_path
  parent :place_range_options, county,session[:active]
end

crumb :show_place do |county, place|
  link 'Place Information', place_path(place)
  case
  when session[:select_place] || place.blank?
    parent :county_options, session[:county] if session[:county].present?
    parent :syndicate_options, session[:syndicate] if session[:syndicate].present?
  when place.present?
    parent :places, county, place
  end

end
crumb :edit_place do |county, place|
  link 'Edit Place Information', edit_place_path(place)
  parent :show_place, county, place
end
crumb :create_place do |county, place|
  link 'Create New Place', new_place_path
  parent :places, county, place
end
crumb :rename_place do |county, place|
  link 'Rename Place', rename_place_path
  parent :places, county, place
end
crumb :relocate_place do |county, place|
  link 'Relocate Place', relocate_place_path
  parent :places, county, place
end
crumb :show_church do |county, place, church|
  if church.present?
    link 'Church Information', church_path(church)
    parent :show_place, county, place
  else
    parent :county_options, session[:county] if session[:county].present?
    parent :syndicate_options, session[:syndicate] if session[:syndicate].present?
  end
end
crumb :edit_church do |county, place, church|
  link 'Edit Church Information', edit_church_path(church)
  parent :show_church, county, place, church
end
crumb :create_church do |county, place|
  link 'Create New Church', new_church_path
  parent :show_place, county, place
end
crumb :rename_church do |county, place, church|
  link 'Rename Church', rename_church_path
  parent :show_church, county, place, church
end
crumb :relocate_church do |county,place,church|
  link 'Relocate Church', relocate_church_path
  parent :show_church, county, place, church
end
crumb :show_register do |county, place, church, register|
  if register.present?
    link 'Register Information', register_path(register)
    parent :show_church, county, place,church
  else
    parent :county_options, session[:county] if session[:county].present?
    parent :syndicate_options, session[:syndicate] if session[:syndicate].present?
  end
end
crumb :edit_register do |county, place, church, register|
  link 'Edit Register Information', edit_register_path(register)
  parent :show_register, county, place, church, register
end
crumb :create_register do |county, place, church|
  link 'Create New Register', new_register_path
  parent :show_church, county, place, church
end
crumb :rename_register do |county, place, church, register|
  link 'Rename Register', rename_register_path
  parent :show_register, county, place, church, register
end

#manage syndicate
crumb :syndicate_options do |syndicate|
  link "Syndicate Options(#{syndicate})", select_action_manage_syndicates_path("?syndicate=#{syndicate}")
  parent :root
end

crumb :userid_details_listing do |syndicate, user|
  case
  when user.nil?
    link 'Syndicate Listing', userid_details_path
  when !user.nil?
    unless session[:manager].nil?
      link 'Syndicate Listing', userid_details_path(:anchor => "#{user.id}", :page => "#{session[:manager]}")
    else
      link 'Syndicate Listing', userid_details_path(:anchor => "#{user.id}")
    end
  end
  case
  when !session[:syndicate].nil? && (session[:role] == 'county_coordinator' ||
                                     session[:role] == 'system_administrator' || session[:role] == 'technical' ||
                                     session[:role] == 'volunteer_coordinator' || session[:role] == 'syndicate_coordinator' )
    parent :syndicate_options, session[:syndicate]
  when session[:role] == 'system_administrator' || session[:role] == 'technical'
    parent :regmanager_userid_options
  else
    parent :syndicate_options, syndicate
  end
end
crumb :syndicate_waiting do |syndicate|
  link 'Files waiting to be processed'
  parent :syndicate_options,syndicate
end


#Profile
crumb :userid_detail do |syndicate, userid_detail, page_name, option|
  link "Profile:#{userid_detail.userid}", userid_detail_path(userid_detail.id)
  case
  when session[:my_own]
    parent :root
  when page_name == 'incomplete_registrations'
    parent :incomplete_registrations, syndicate
  when option
    parent :selection_user_id, option, syndicate
  when session[:manage_user_origin] == 'manage syndicate'
    parent :syndicate_options, syndicate
  when session[:edit_userid]
    syndicate = syndicate
    syndicate = 'all'  if session[:role] == 'system_administrator' || session[:role] == 'technical'
    parent :userid_details_listing, syndicate, userid_detail
  else
    parent :coordinator_userid_options
  end
end

crumb :selection_user_id do |selection, syndicate|
  link "#{selection}", selection_userid_details_path(option: selection, syndicate: syndicate)
  case
  when session[:manage_user_origin] == 'manage syndicate'
    parent :syndicate_options, syndicate
  when session[:edit_userid]
    if syndicate.nil? || syndicate == 'all'
      parent :regmanager_userid_options
    else
      parent :syndicate_options, syndicate
    end
  else
    parent :coordinator_userid_options
  end

end

#manage userids
crumb :regmanager_userid_options do
  link 'Userid Management Options', options_userid_details_path
  parent :root
end
crumb :coordinator_userid_options do
  link 'Profile Display Selection', display_userid_details_path
  parent :root
end
crumb :rename_userid do |user|
  link 'Rename Userid', rename_userid_details_path
  parent :userid_detail, user.syndicate,user
end
crumb :role_listing do
  link 'Role Listing'
  parent :regmanager_userid_options
end

#Incomplete Registrations
crumb :incomplete_registrations do |syndicate|
  link 'Incomplete Registration Listing', incomplete_registrations_userid_details_path
  if syndicate == 'all'
    parent :regmanager_userid_options
  else
    parent :syndicate_options,syndicate
  end
end


#Physical Files

crumb :physical_files_options do
  link 'Physical Files Options', select_action_physical_files_path
  parent :root
end
crumb :physical_files do |syndicate, type|
  link 'Listing of Physical Files', physical_files_path
  if type == 'syndicate'
    parent :syndicate_options, syndicate
  else
    parent :physical_files_options
  end
end
crumb :show_physical_files do |physical_file|
  link 'Show a Physical File', physical_file_path(physical_file)
  parent :physical_files
end

#csvfiles
crumb :new_csvfile do |csvfile|
  link 'Upload New File', new_csvfile_path
  case
  when session[:my_own]
    parent :files, nil
  when session[:county]
    parent :county_options, session[:county]
  when session[:syndicate]
    parent :syndicate_options, session[:syndicate]
  end
end
crumb :edit_csvfile do |csvfile, file|
  link 'Replace File', edit_csvfile_path
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
  if session[:archived_contacts]
    link 'Archived Feedbacks', list_archived_feedbacks_path
  else
    link 'Active Feedbacks', feedbacks_path
  end
  parent :root
end
crumb :archived_feedbacks do
  link 'Archived Feedbacks', list_archived_feedbacks_path
  parent :root
end
crumb :show_feedback do |feedback|
  link 'Show Feedback', feedback_path(feedback)
  if session[:archived_contacts]
    parent :archived_feedbacks
  else
    parent :feedbacks
  end
end
crumb :edit_feedback do |feedback|
  link 'Edit Feedback', edit_feedback_path(feedback)
  if session[:archived]
    parent :archived_feedbacks
  else
    parent :feedbacks
  end
end
crumb :feedback_form_for_selection do ||
    link 'Form for Selection'
  if session[:archived_contacts]
    parent :archived_feedbacks
  else
    parent :feedbacks
  end
end
crumb :create_feedback_reply do |feedback|
  link 'Create Feedback Reply'
  parent :show_feedback, feedback
end

#manage contacts
crumb :contacts do
  if session[:archived_contacts]
    link 'Archived Contacts', list_archived_contacts_path
  else
    link 'Active Contacts', contacts_path
  end
  parent :root
end
crumb :archived_contacts do
  link 'Archived Contacts', list_archived_contacts_path
  parent :root
end
crumb :show_contact do |contact|
  link 'Show Contact', contact_path(contact)
  if session[:archived_contacts]
    parent :archived_contacts
  else
    parent :contacts
  end
end
crumb :edit_contact do |contact|
  link 'Edit Contact', edit_contact_path(contact)
  if session[:archived_contacts]
    parent :archived_contacts
  else
    parent :contacts
  end
end
crumb :contact_form_for_selection do ||
    link 'Form for Selection'
  if session[:archived_contacts]
    parent :archived_contacts
  else
    parent :contacts
  end
end
crumb :create_contact_reply do |message|
  link 'Create Reply for Contact', reply_contact_path(message.id)
  parent :contacts
end
# .....................Nessages...............................

crumb :messages do
  case
  when session[:message_base] == 'general' && session[:archived_contacts]
    link 'Archived Messages', list_archived_messages_path
  when session[:message_base] == 'general' && !session[:archived_contacts]
    link 'Active Messages', messages_path
  when session[:message_base] == 'syndicate' && session[:archived_contacts]
    link 'Archived Syndicate Messages', list_archived_syndicate_messages_path
  when session[:message_base] == 'syndicate' && !session[:archived_contacts]
    link 'Active Syndicate Messages', list_archived_syndicate_messages_path
  when session[:message_base] == 'userid_messages'
    link 'User Messages', userid_messages_path
  end
  if session[:message_base] == 'syndicate'
    parent :syndicate_options, session[:syndicate]
  else
    parent :root
  end
end

crumb :message_to_syndicate do
  if session[:archived_contacts]
    link 'Archived Syndicate Messages', list_archived_syndicate_messages_path(:source => params[:source])
  else
    link 'Active Syndicate Messages', list_syndicate_messages_path(:source => params[:source])

  end
  parent :syndicate_options, session[:syndicate]
end

crumb :message_form_for_selection do
  link 'Form for Selection'
  if session[:syndicate].present?
    parent :message_to_syndicate
  else
    parent :messages
  end
end

crumb :show_message do |message|
  p 'show message.................................................................................'
  p params[:action]
  p params[:source]
  p message
  p session[:message_id]
  p session[:original_message_id]
  p session[:message_base]
  link 'Show Message', message_path(message, source: params[:source])
  case
  when session[:message_base] == 'userid_messages' && params[:source] == 'show_reply_messages'
    p 's1'
    parent :reply_messages_list, Message.id(session[:original_message_id]).first, :source => params[:source]
  when session[:message_base] == 'userid_messages' && params[:source] == 'userid_messages'
    p 's2'
    parent :userid_messages
  when session[:message_base] == 'userid_messages' && params[:source] == 'show'
    p 's3'
    parent :userid_messages
  when session[:message_base] == 'syndicate' && params[:source] == 'show_reply_messages'
    p 'ss1'
    parent :replies_list_syndicate_messages, Message.id(session[:original_message_id]).first, :source => params[:source]
  when session[:message_base] == 'syndicate' && params[:source] == 'userid_messages'
    p 'ss2'
    parent :show_list_syndicate_messages
  when session[:message_base] == 'syndicate' && params[:source] == 'show'
    p 'ss3'
    parent :show_list_syndicate_messages, message, :source => params[:source]
  when session[:message_base] == 'general' && params[:source] == 'show_reply_messages'
    p 'sg1'
    parent :reply_messages_list, Message.id(session[:original_message_id]).first, :source => params[:source]
  when session[:message_base] == 'general' && params[:source] == 'userid_messages'
    p 'sg2'
    parent :messages
  when session[:message_base] == 'general' && params[:source] == 'show'
    p 'sg3'
    parent :messages, message, :source => params[:source]
  when message.source_feedback_id.present?
    feedback = Feedback.id(message.source_feedback_id).first
    parent :feedback_messages, feedback
  when message.source_contact_id.present?
    contact = Contact.id(message.source_contact_id).first
    parent :contact_messages, contact
  else
    parent :messages
  end
end
crumb :show_list_syndicate_messages do |message|
  p 'show list message.................................................................................'
  p params[:action]
  p params[:source]

  link 'Show Syndicate Message', message_path(message, :source => params[:source])
  case
  when params[:source] == 'show_reply_messages' && params[:source] == 'list_syndicate_messages'
    parent :replies_list_syndicate_messages, Message.id(message.source_message_id).first
  else
    parent :message_to_syndicate
  end
end

crumb :replies_list_syndicate_messages do |message|
  link 'Replies to Syndicate Message', show_reply_messages_path(message, :source => params[:source] )
  parent :message_to_syndicate
end


crumb :userid_messages do
  p 'userid_messages'
  link 'User Messages', userid_messages_path
end

crumb :userid_reply_messages do
  link 'Reply Messages Recieved', userid_reply_messages_path
  parent :userid_messages
end

crumb :reply_messages_list do |message|
  p 'show reply messages message.................................................................................'
  p params[:action]
  p params[:source]
  p message
  link 'Reply Messages List', show_reply_messages_path(message.id, source: params[:source])
  case
  when session[:message_base] == 'syndicate' && params[:source].present?
    p 'r1'
    parent :replies_list_syndicate_messages, message
  when session[:message_base] == 'syndicate' && params[:source].blank?
    p 'r2'
    parent :replies_list_syndicate_messages, message
  when session[:message_base] == 'userid_messages' && (params[:source] == 'userid_messages' || params[:source] == 'show_reply_messages')
    p 'r3'
    parent :userid_messages
  when session[:message_base] == 'userid_messages' && params[:source] == 'show'
    p 'r5'
    parent :show_message, message, source: params[:source]
  else
    p 'r6'
    parent :root
  end
end

crumb :user_reply_messages_list do |message|
  link 'User Reply Messages List', user_reply_messages_path(message.id)
  parent :reply_messages_list, message
end

crumb :show_messages_user do |message|
  link 'Show User Message', message_path(message.id)
  parent :userid_messages
end

crumb :show_reply_message do |message|
  source_message = Message.id(message.source_message_id).first
  link 'Show Reply Message', message_path(message.id)
  parent :reply_messages_list, source_message
end

crumb :feedback_messages do |message|
  link 'Feedback Messages', feedback_reply_messages_path(message.id)
  parent :feedbacks
end

crumb :contact_messages do |message|
  link 'Contact Messages', contact_reply_messages_path(message.id)
  parent :contacts
end

crumb :list_contact_reply_messages do
  link 'All Contact Reply Messages', list_contact_reply_message_path
  parent :contacts
end

crumb :list_feedback_reply_messages do
  link 'All Feedback Reply Messages', list_contact_reply_message_path
  parent :feedbacks
end

crumb :show_feedback_message do |message|
  link 'Show Feedback Message', message_path(message)
  parent :messages
  parent :message_to_syndicate if session[:syndicate]
end

crumb :edit_message do |message|
  link 'Edit Message', edit_message_path(message)
  p 'Edit Message'
  p params[:source]
  case
  when params[:source] == 'list_syndicate_messages'
    parent :show_list_syndicate_messages, message
  else
    parent :show_message, message
  end
end

crumb :create_message do |message|
  link 'Create Message', new_message_path(message)
  if session[:syndicate]
    parent :message_to_syndicate
  else
    parent :messages
  end
end

crumb :create_reply do |message, original_message_id|
  link 'Create Reply Message', reply_messages_path(message.id, source: params[:source])
  if session[:message_base] == 'syndicate'
    parent :message_to_syndicate
  else
    parent :show_message, original_message_id, source: params[:source]
  end
end

crumb :send_message do |message|
  p 'send_message'
  p request.referer
  p params[:source]
  p session[:message_base]
  p message
  link 'Send Message', send_message_messages_path(message, source: params[:source])
  case session[:message_base]
  when 'syndicate'
    p 'sse1'
    parent :show_list_syndicate_messages, message, source: params[:source]
  when 'general'
    p 'sse2'
    parent :show_message, message, source: params[:source]
  else
    p 'sse3'
    parent :show_message, message, source: params[:source]
  end
end

crumb :send_reply_message do |message|
  source_message = Message.id(message.source_message_id).first
  link 'Send Message', send_message_messages_path(message)
  parent :create_reply, source_message
  #parent :show_message, message #if message.source_message_id.blank?
end

#............................................................Denominations......................................
crumb :denominations do
  link 'Denominations', denominations_path
  parent :root
end
crumb :show_denomination do |denomination|
  link 'Show Denomination', denomination_path(denomination)
  parent :denominations
end
crumb :edit_denomination do |denomination|
  link 'Edit Denomination', edit_denomination_path(denomination)
  parent :show_denomination, denomination
end
crumb :create_denomination do |denomination|
  link 'Create Denomination', new_denomination_path(denomination)
  parent :denominations
end
crumb :select_attic_files do
  link 'Select Userid', select_attic_files_path
  parent :root
end
crumb :show_attic_files do |user|
  link 'Listing of Attic Files', attic_files_path(user)
  parent :select_attic_files
end
crumb :countries do
  link 'Countries', countries_path
  parent :root
end
crumb :show_countries do |country|
  link 'Show Country', country_path(country)
  parent :countries
end
crumb :edit_country do |country|
  link 'Edit Country', edit_country_path(country)
  parent :show_countries, country
end
crumb :counties do
  link 'Counties', counties_path
  parent :root
end
crumb :show_counties do |county|
  link 'Show County', county_path(county)
  parent :counties
end
crumb :edit_county do |county|
  link 'Edit County', edit_county_path(county)
  parent :show_counties, county
end
crumb :syndicates do
  link 'Syndicates', syndicates_path
  parent :root
end
crumb :show_syndicate do |syndicate|
  link 'Show Syndicate', syndicate_path(syndicate)
  parent :syndicates
end
crumb :edit_syndicate do |syndicate|
  link 'Edit Syndicate', edit_syndicate_path(syndicate)
  parent :show_syndicate, syndicate
end
crumb :create_syndicate do |syndicate|
  link 'Create Syndicate', new_syndicate_path(syndicate)
  parent :syndicates
end

crumb :zero_year_records do |record|
  link 'Zero Year Records', show_zero_startyear_entries_freereg1_csv_file_path(id: "#{record.id}")
  parent :files
end

crumb :zero_year_record_detail do |entry,file|
  @get_zero_year_records = 'true'
  link 'Zero Year Record Detail', freereg1_csv_entry_path(entry, 'zero_record' => @get_zero_year_records)
  parent :zero_year_records, file
end

crumb :edit_zero_year_record do |entry,file|
  link 'Edit Zero Year Record', edit_freereg1_csv_entry_path(entry)
  parent :zero_year_record_detail, entry,file
  parent :zero_year_records, file if request.referer.include?'zero_year_entries' unless request.referer.nil?
end

crumb :listing_of_zero_year_entries do |file|
  link 'Listing of Zero Year Entries', zero_year_freereg1_csv_file_path(id: "#{file.id}")
  parent :show_file, file
end

crumb :show_zero_year_entry do |entry, file|
  @zero_year = 'true'
  link 'Show Zero Year Entry', freereg1_csv_entry_path(entry, 'zero_listing' => @zero_year)
  parent :listing_of_zero_year_entries, file
end

crumb :edit_zero_year_entry do |entry,file|
  link 'Edit Zero Year Entry', edit_freereg1_csv_entry_path(entry)
  parent :show_zero_year_entry, entry,file
  parent :listing_of_zero_year_entries, file if request.referer.match(/zero_year/) unless request.referer.nil?
end



# breadcrumbs from 'assignments'
crumb :my_own_assignments do |user|
  link "#{user.userid} Assignments", my_own_assignment_path(user)
  parent :root
end

# from 'assignments' => 'list image groups under my syndicate'
crumb :request_assignments_by_syndicate do |user|
  link "Image Groups Under My Syndicate", my_list_by_syndicate_image_server_group_path(user)
  parent :my_own_assignments, user
end

# from 'assignments' => 'Image Groups Available for Allocation(By County)'
# from 'all allocated image groups' => 'Image Groups Available for Allocation(By County)'
crumb :request_assignments_by_county do |user,county|
  link "Image Groups Available for Allocation(#{county})", my_list_by_county_image_server_group_path(county)
  parent :syndicate_available_groups_by_county_select_county, user
end

# from 'assignments' => 'LS'
crumb :my_own_assignment do |user|
  link 'Assignment'
  parent :my_own_assignments, user
end




# breadcrumbs from 'manage syndicates' => 'manage images'
crumb :syndicate_manage_images do |syndicate|
  link 'All Allocated Image Groups', manage_image_group_manage_syndicate_path(syndicate)
  parent :syndicate_options, session[:syndicate]
end

# from 'manage syndicates' => 'manage images' => 'image groups available for allocation'
crumb :syndicate_available_groups_by_county_select_county do |user|
  link 'Select County', select_county_assignment_path

  if session[:my_own]
    parent :my_own_assignments, user
  else
    parent :syndicate_manage_images, session[:syndicate]
  end
end

# from 'manage syndicates' => 'manage images' => 'list assignment by userid'
crumb :syndicate_all_assignments_select_user do |syndicate|
  link 'Select User', select_user_assignment_path(session[:syndicate], :assignment_list_type=>'all')
  parent :syndicate_manage_images, session[:syndicate]
end

crumb :syndicate_all_assignments do |syndicate|
  link 'List User Assignments', list_assignments_by_syndicate_coordinator_assignment_path(session[:syndicate], :assignment_list_type=>'all')
  if session[:list_user_assignments] == true
    parent :syndicate_all_assignments_select_user, session[:syndicate]
  else
    parent :syndicate_manage_images, session[:syndicate]
  end
end

crumb :syndicate_all_assignment do |syndicate|
  link 'List User Assignment'
  if session[:list_user_assignments] == true
    parent :syndicate_all_assignments, session[:syndicate]
  else
    parent :syndicate_manage_images, session[:syndicate]
  end
end

crumb :syndicate_all_reassign do |syndicate|
  link 'Re_assign Assignment'
  parent :syndicate_all_assignments, session[:syndicate]
end

# from 'manage syndicate' => 'manage images' => 'list fully transcribed groups'
crumb :fully_transcribed_groups do |syndicate|
  link 'List Fully Transcribed Groups', list_fully_transcribed_group_manage_syndicate_path(session[:syndicate])
  parent :syndicate_manage_images, session[:syndicate]
end

# from 'manage syndicate' => 'manage images' => 'list fully reviewed groups'
crumb :fully_reviewed_groups do |syndicate|
  link 'List Fully Reviewed Groups', list_fully_reviewed_group_manage_syndicate_path(session[:syndicate])
  parent :syndicate_manage_images, session[:syndicate]
end

# from 'manage syndicates' => 'manage images' => 'List Submitted Transcribe assignment'
crumb :submitted_transcribe_assignments do |syndicate|
  link 'List Submitted_Transcription Assignments', list_submitted_transcribe_assignments_assignment_path(session[:syndicate])
  parent :syndicate_manage_images, session[:syndicate]
end

# from 'manage syndicates' => 'manage images' => 'List Submitted Review Assignment'
crumb :submitted_review_assignments do |syndicate|
  link 'List Submitted_Review Assignments', list_submitted_review_assignments_assignment_path(session[:syndicate])
  parent :syndicate_manage_images, session[:syndicate]
end

crumb :syndicate_image_group_assignments do |user,syndicate,county,register,source,group|
  link 'User Assignments', assignment_path(group)
  parent :image_server_images, user,syndicate,county,register,source,group
end

crumb :syndicate_image_group_assignment do |user,syndicate,county,register,source,group|
  link 'User Assignment'
  parent :syndicate_image_group_assignments, user,syndicate,county,register,source,group
end





# from 'manage counties' => 'Manage Images'
crumb :county_manage_images do |county, browse_source|
  if browse_source.nil?
    link 'All Sources', selection_active_manage_counties_path(:option =>'Manage Images')
  else
    link 'All Sources', selection_active_manage_counties_path(:option => 'Manage Images', :anchor => browse_source)
  end
  parent :county_options, session[:county]
end

# from 'manage counties' => 'Manage Images' => 'List All Image Groups'
crumb :county_manage_images_selection do |county, browse_source|
  case session[:image_group_filter]
  when 'all'
    link 'List All Image Groups', manage_image_group_manage_county_path
  when 'unallocate'
    link 'List Unallocated Image Groups', manage_unallocated_image_group_manage_county_path
  when 'allocate request'
    link 'List Allocate Request Image Groups', manage_allocate_request_image_group_manage_county_path
  when 'completion_submitted'
    link 'List Completion Submitted Allocations', manage_completion_submitted_image_group_manage_county_path
  when 'syndicate'
    link 'Image Groups Allocated by Syndicate', sort_image_group_by_syndicate_path(county)
  when 'place'
    link 'Image Groups Allocated by Place', sort_image_group_by_place_path
  when 'uninitialized'
    link 'List Unitialized Sources', uninitialized_source_list_path(county)
  end
  parent :county_manage_images, session[:county], browse_source
end





# from 'register' => Sources        (is taken out right now)
crumb :image_sources do |register|
  link 'Sources', index_source_path(register)
  parent :county_manage_images
end

crumb :new_image_source do |register,source|
  link 'Create New Source'
  parent :image_sources, register
end





# breadcrumb for image_source
crumb :show_image_source do |register,source|
  case source.source_name
  when 'Image Server'
    link 'Image Server', source_path(source)
    if session[:manage_user_origin] == 'manage syndicate'
      # from 'manage syndicates' => 'Manage Images' => 'List Fully Reviewed/Transcribed Groups'
      case session[:image_group_filter]
      when 'fully_transcribed'
        parent :fully_transcribed_groups, session[:syndicate]
      when 'fully_reviewed'
        parent :fully_reviewed_groups, session[:syndicate]
      else
        parent :syndicate_manage_images, session[:syndicate]
      end
    else
      parent :county_manage_images_selection, session[:county], source.id.to_s
    end
  when 'Other Server1'
    link 'Other Server1', source_path(source)
    parent :image_sources, register
  when 'Other Server2'
    link 'Other Server2', source_path(source)
    parent :images_sources, register
  when 'Other Server3'
    link 'Other Server3', source_path(source)
    parent :image_sources, register
  end
end

crumb :edit_image_source do |register,source|
  link 'Edit Image Server'
  parent :show_image_source, register,source
end

crumb :initialize_image_source do |register,source|
  link 'Initialize Image Server'
  parent :show_image_source, register,source
end

crumb :propagate_image_source do |register,source|
  link 'Propagate Image Server'
  parent :show_image_source, register,source
end





# breadcrumb for Image Server Groups
crumb :image_server_groups do |user,syndicate,county,register,source|
  link 'Image Groups', index_image_server_group_path(source)
  parent :show_image_source, register,source
end

crumb :allocate_image_server_group do |user,syndicate,county,register,source,group|
  link 'Allocate Image Group'
  parent :image_server_groups, user,syndicate,county,register,source
end

crumb :new_image_server_group do |user,syndicate,county,register,source,group|
  link 'Create Image Group'
  parent :image_server_groups, user,syndicate,county,register,source
end

crumb :initialize_image_server_group do |user,syndicate,county,register,source,group|
  link 'Initialize Image Group'
  parent :image_server_groups, user,syndicate,county,register,source
end


crumb :show_image_server_group do |user,syndicate,county,register,source,group|
  link 'Image Group', image_server_group_path(group)

  if session[:from_source] == true
    parent :image_server_groups, user,syndicate,county,register,source
  else
    # image group from list assignments result
    if !session[:assignment_filter_list].nil? && !session[:assignment_filter_list].empty?
      case session[:assignment_filter_list]
      when 'syndicate'        # from Assignments => 'List Image Groups Under My Syndicate'
        parent :request_assignments_by_syndicate, user
      when 'county'           # from 'Image Groups Available for Allocation(county)'
        parent :request_assignments_by_county, user,syndicate
      end
      # image groups from list groups result
    else
      if session[:manage_user_origin] == 'manage syndicate'
        case session[:image_group_filter]
        when 'fully_transcribed'
          parent :fully_transcribed_groups
        when 'fully_reviewed'
          parent :fully_reviewed_groups
        else
          parent :syndicate_manage_images
        end
      elsif session[:manage_user_origin] == 'manage county'
        parent :county_manage_images_selection, register, source
      end
    end
  end
end

crumb :edit_image_server_group do |user,syndicate,county,register,source,group|
  link 'Edit Image Group'
  parent :show_image_server_group, user,syndicate,county,register,source,group
end

crumb :upload_image_server_group do |user,syndicate,county,register,source,group|
  link 'Upload Images Report'
  parent :show_image_server_group, user,syndicate,county,register,source,group
end




# breadcrumb for Image Server Images
crumb :image_server_images do |user,syndicate,county,register,source,group|
  link 'Images', index_image_server_image_path(group)
  parent :show_image_server_group, user,syndicate,county,register,source,group
end

crumb :move_image_server_image do |user,syndicate,county,register,source,group,image|
  link 'Move Images'
  parent :image_server_images, user,syndicate,county,register,source,group
end

crumb :propagate_image_server_image do |user,syndicate,county,register,source,group,image|
  link 'Propagate Images'
  parent :image_server_images, user,syndicate,county,register,source,group
end

crumb :reassign_image_server_image do |user,syndicate,county,register,source,group,image|
  link 'Reassign Images'
  parent :image_server_images, user,syndicate,county,register,source,group
end

crumb :show_image_server_image do |user,syndicate,county,register,source,group,image|
  link 'Image', image_server_image_path(image)
  parent :image_server_images, user,syndicate,county,register,source,group
end

crumb :edit_image_server_image do |user,syndicate,county,register,source,group,image|
  link 'Edit Image'
  parent :show_image_server_image, user,syndicate,county,register,source,group,image
end



# breadcrumb for GAP
crumb :gaps do |user,syndicate,county,register,source|
  link 'GAPs', index_gap_path(source)
  parent :show_image_source, register,source
end

crumb :show_gap do |user,syndicate,county,register,source|
  link 'GAP'
  parent :gaps, user,syndicate,county,register,source
end

crumb :new_gap do |user,syndicate,county,register,source|
  link 'Create New GAP'
  parent :gaps, user,syndicate,county,register,source
end

crumb :edit_gap do |user,syndicate,county,register,source|
  link 'Edit GAP'
  parent :gaps, user,syndicate,county,register,source
end


crumb :gap_reasons do
  link 'GAP Reasons', gap_reasons_path
  parent :root
end

crumb :show_gap_reason do |gap_reason|
  link 'Show GAP Reason', gap_reason_path(gap_reason)
  parent :gap_reasons
end

crumb :edit_gap_reason do |gap_reason|
  link 'Edit GAP Reason', edit_gap_reason_path(gap_reason)
  parent :show_gap_reason, gap_reason
end

crumb :create_gap_reason do |gap_reason|
  link 'Create GAP Reason', new_gap_reason_path(gap_reason)
  parent :gap_reasons
end


# crumb :projects do
#   link 'Projects', projects_path
# end

# crumb :project do |project|
#   link project.name, project_path(project)
#   parent :projects
# end

# crumb :project_issues do |project|
#   link 'Issues', project_issues_path(project)
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
