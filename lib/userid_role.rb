module UseridRole
  VALUES = ["researcher","trainee",'pending', 'transcriber','syndicate_coordinator','county_coordinator','country_coordinator',
            'volunteer_coordinator','data_manager', 'technical','system_administrator', 'contacts_coordinator','project_manager','executive_director',
            'publicity_coordinator', 'genealogy_coordinator', 'documentation_coordinator', 'engagement_coordinator','computer', 'website_coordinator', 'general_communication_coordinator']
  OPTIONS = {
    'researcher' => [ "Profile","Roadmap"],
    'computer' => [ "Profile","Roadmap"],
    'trainee' => [ "Assignments", "Batches","Profile", "Batches","Roadmap"],
    'pending' => [ "Profile"],
    'transcriber' => [  "Assignments", "Batches", "Profile", "Roadmap"],
    'syndicate_coordinator' => [ "Assignments", "Batches", "Manage Syndicate", "Profile", "Roadmap"],
    'contacts_coordinator'=> ["Assignments", "Batches", "Contacts","Display County Coordinators","Display Syndicate Coordinators","Display Userids","Feedback", "Manage Counties", "Profile", "System Documentation" ,"Roadmap"],
    'county_coordinator' =>  [ "Assignments", "Batches", "Contacts",  "Display Userids","Manage County", "Manage Syndicate", "Profile","Roadmap"],
    'country_coordinator' => ["Assignments", "Batches", "Contacts","Display Userids","Manage Country", "Manage County","Manage Syndicate", "Profile","Roadmap"],
    'volunteer_coordinator' => [ "Assignments", "Batches", "Contacts","Manage Syndicates", "Manage Userids","Profile","Roadmap"],
    'data_manager' => [ "Access Attic", "Assignments", "Batches", "Contacts", "Denominations", "Display Userids","Display Syndicate Coordinators","Display County Coordinators", "Manage Counties", "Manage Syndicates", "Physical Files", "Profile", "Roadmap" ],
    'technical' => [  "Access Attic", "Assignments", "Batches", "Manage Assignments", "Contacts", "Feedback", "Profile","RefineryCMS", "Roadmap" ,"Search Performance",  "Site Statistics",
                      "System Documentation"],
    'system_administrator' =>[  "Access Attic","Assignments","Batches", "Contacts", "County Coordinators", "Country Coordinators","Denominations","GAP Reasons","Feedback",
                                "Manage Counties","Manage Countries", "Manage Image Server", "Manage Syndicates" ,"Manage Userids",  "Message System",  "Physical Files","Profile","RefineryCMS","Roadmap","Search Performance","Site Statistics",
                                "Software Version Information", "Syndicate Coordinators","System Documentation" ],
    'project_manager' =>[  "Assignments","Batches","Contacts", "Manage Userids",  "Feedback", "Profile",  "RefineryCMS","Roadmap" ,"Search Performance","Site Statistics",
                           "System Documentation"],
    'executive_director' =>[  "Assignments", "Batches", "Contacts", "County Coordinators","Country Coordinators", "Feedback","Profile","Manage Userids", "Message System","RefineryCMS","Roadmap","Site Statistics","Search Performance",
                              "Syndicate Coordinators", "System Documentation"],
    'publicity_coordinator'=> [ "Assignments", "Batches", "Contacts", "Profile","Roadmap","System Documentation" ],
    'genealogy_coordinator'=> [ "Assignments", "Batches", "Contacts","Profile", "Roadmap" ,"System Documentation" ],
    'documentation_coordinator' => [  "Assignments", "Batches",  "Display Userids","Feedback", "Manage Syndicates", "Manage Counties", "Profile","RefineryCMS","Roadmap",
                                       "System Documentation" ],
    'engagement_coordinator' => [  "Assignments", "Batches", "Display Userids",  "Feedback", "Message System", "Profile", "RefineryCMS" ,"Roadmap", "System Documentation" ],
    'website_coordinator' => [ "Batches", "Contacts","Display Userids", "Feedback", "Message System", "Profile", "RefineryCMS" ,"Roadmap", "System Documentation" ],
    'general_communication_coordinator' => [ "Batches", "Contacts","Display Userids", "Feedback", "Message System", "Profile", "RefineryCMS" ,"Roadmap", "System Documentation" ],
  }

  OPTIONS_TRANSLATION = {
    "Denominations" => "/denominations",
    "GAP Reasons" => "/gap_reasons", 
    "Saved Searches" => "/my_saved_searches",
    "Profile" => "/userid_details/my_own" ,
    "Batches" => "/freereg1_csv_files/my_own" ,
    "Manage Syndicate" =>  "/manage_syndicates",
    "Manage Syndicates" =>  "/manage_syndicates",
    "Manage County" => "/manage_counties" ,
    "Manage Country" => "/manage_countries" ,
    "Manage Countries" => "/countries" ,
    "Manage Counties" => "/manage_counties" ,
    "Manage Image Server" => "/sources/access_image_server",
    "Manage Userids"=> "/userid_details/options" ,
    "Display Userids" => "/userid_details/display" ,
    "Display Syndicate Coordinators" => "/syndicates/display" ,
    "Display County Coordinators" => "/counties/display" ,
    "Syndicate Coordinators" => "/syndicates" ,
    "County Coordinators" => "/counties" ,
    "Country Coordinators" => "/countries" ,
    "Upload New Batch"  =>   "/csvfiles/new", #"/manage_counties/selection?option=Upload New Batch",
    "RefineryCMS" =>  "/manage_resources/pages", #        "/cms/refinery/pages",
    "Access Attic" => "/attic_files/select" ,
    "Physical Files" => "/physical_files/select_action",
    "Site Statistics" => "/site_statistics",
    "Search Performance" => "/search_queries/report" ,
    "Software Version Information" => "/software_versions",
    "Feedback" => "/feedbacks",
    "Contacts" => "/contacts",
    "System Documentation" => "/cms/system-documents",
    "Roadmap" => "/cms/system-documents/development-roadmap",
    "Logout" => "/refinery/logout",
    "Message System" => "/messages", 
    "Manage Images" => "/sources",
    "Assignments" => "/assignments/my_own"
  }
  USERID_MANAGER_OPTIONS = ["Select specific userid","Select specific email","Select specific surname/forename","Browse userids","Select Role", "Select Secondary Role","Incomplete Registrations","Create userid", "Transcriber Statistics"]
  USERID_ACCESS_OPTIONS = ["Select specific userid","Select specific email", "Select specific surname/forename"]

  USERID_OPTIONS_TRANSLATION = {
    #todo clean up first 2
    "Browse userids" => "/userid_details/selection?option=Browse userids",
    "Incomplete Registrations" => "/userid_details/incomplete_registrations",
    "Create userid"=> "/userid_details/selection?option=Create userid",
    "Select specific email" =>  "/userid_details/selection?option=Select specific email",
    "Select specific userid"=> "/userid_details/selection?option=Select specific userid",
    "Select specific surname/forename"=> "/userid_details/selection?option=Select specific surname/forename",
    "Select Role" => "/userid_details/person_roles",
    "Select Secondary Role" => "/userid_details/secondary_roles",
    "Transcriber Statistics" => "/userid_details/transcriber_statistics"
  }
  FILE_MANAGEMENT_OPTIONS = ['Upload New Batch','List by Number of Errors then Filename', 'List by Filename',
                             'List by uploaded date (ascending)', 'List by uploaded date (descending)', 'List files waiting to be processed','Review Specific Batch' ]
  FILE_OPTIONS_TRANSLATION ={
    'Upload New Batch' =>  "/csvfiles/new",
    'List by Number of Errors then Filename' =>  "/freereg1_csv_files/selection?option=List by Number of Errors then Filename",
    'List by Filename' =>  "/freereg1_csv_files/selection?option=List by Filename",
    'List by uploaded date (ascending)' =>  "/freereg1_csv_files/selection?option=List by uploaded date (ascending)",
    'List by uploaded date (descending)'  =>  "/freereg1_csv_files/selection?option=List by uploaded date (descending)",
    'List files waiting to be processed' => "/freereg1_csv_files/selection?option=List files waiting to be processed",
    'Review Specific Batch' => "/freereg1_csv_files/selection?option=Review Specific Batch"
  }
  COUNTY_MANAGEMENT_OPTIONS = ['All Places', 'Active Places', 'Specific Place','Places with Unapproved Names', 'Review Batches with Errors',
                               'Review Batches by Filename', 'Review Batches by Userid then Filename',
                               'Review Batches by Most Recent Date of Change',  'Review Batches by Oldest Date of Change','Review Specific Batch',
                               "Upload New Batch",'Manage Images']
  COUNTY_OPTIONS_TRANSLATION = {
    'All Places' => "/manage_counties/selection?option=Work with All Places",
    'Active Places' => "/manage_counties/selection?option=Work with Active Places",
    'Specific Place' => "/manage_counties/selection?option=Work with Specific Place",
    'Places with Unapproved Names' => "/manage_counties/selection?option=Places with Unapproved Names",
    'Review Batches with Errors' => "/manage_counties/selection?option=Review Batches with Errors",
    'Review Batches by Filename' => "/manage_counties/selection?option=Review Batches by Filename",
    'Review Batches by Userid then Filename' => "/manage_counties/selection?option=Review Batches by Userid then Filename",
    'Review Batches by Most Recent Date of Change' => "/manage_counties/selection?option=Review Batches by Most Recent Date of Change",
    'Review Batches by Oldest Date of Change' => "/manage_counties/selection?option=Review Batches by Oldest Date of Change",
    'Review Specific Batch'=> "/manage_counties/selection?option=Review Specific Batch",
    'Upload New Batch' =>  "/csvfiles/new",
    'Manage Images' => '/manage_counties/selection?option=Manage Images'
  }
  SYNDICATE_MANAGEMENT_OPTIONS =  ['Review Active Members' ,'Review All Members', 'Select Specific Member by Userid',
                                   'Select Specific Member by Email Address','Select Specific Member by Surname/Forename',"Incomplete Registrations","Create userid","Syndicate Messages",'Review Batches with Errors','Review Batches by Filename',
                                   'Review Batches by Userid then Filename', 'Review Batches by Most Recent Date of Change','Review Batches by Oldest Date of Change',
                                   'Review Specific Batch','List files waiting to be processed','List files NOT processed',"Upload New Batch",'Change Recruiting Status','Manage Images']
  SYNDICATE_OPTIONS_TRANSLATION = {
    'Review Active Members' => "/manage_syndicates/selection?option=Review Active Members",
    'Review All Members'=> "/manage_syndicates/selection?option=Review All Members",
    'Select Specific Member by Userid'=> "/manage_syndicates/selection?option=Select Specific Member by Userid",
    'Select Specific Member by Email Address'=> "/manage_syndicates/selection?option=Select Specific Member by Email Address",
    'Select Specific Member by Surname/Forename' => "/manage_syndicates/selection?option=Select Specific Member by Surname/Forename",
    "Incomplete Registrations" => "/userid_details/incomplete_registrations",
    "Create userid"=> "/userid_details/selection?option=Create userid",
    "Syndicate Messages" => "/messages/list_syndicate_messages?source=list_syndicate_messages",
    'Review Batches with Errors'=> "/manage_syndicates/selection?option=Review Batches with Errors",
    'Review Batches by Filename' => "/manage_syndicates/selection?option=Review Batches by Filename",
    'Review Batches by Userid then Filename' => "/manage_syndicates/selection?option=Review Batches by Userid then Filename",
    'Review Batches by Most Recent Date of Change' => "/manage_syndicates/selection?option=Review Batches by Most Recent Date of Change",
    'Review Batches by Oldest Date of Change' => "/manage_syndicates/selection?option=Review Batches by Oldest Date of Change",
    'Review Specific Batch'=> "/manage_syndicates/selection?option=Review Specific Batch",
    'Upload New Batch' =>  "/csvfiles/new",
    'List files waiting to be processed'  => "/manage_syndicates/display_files_waiting_to_be_processed",
    'List files NOT processed' => "/manage_syndicates/display_files_not_processed",
    'Change Recruiting Status' => "/manage_syndicates/selection?option=Change Recruiting Status",
    'Manage Images' => "/manage_syndicates/selection?option=Manage Images"
  }
  PHYSICAL_FILES_OPTIONS =  ['Waiting to be processed','Files not processed','Processed but no file','Browse files' ,'Files for specific userid' ]

  PHYSICAL_FILES_OPTIONS_TRANSLATION ={
    'Browse files' => "/physical_files/all_files",
    'Files not processed' => '/physical_files/file_not_processed',
    'Processed but no file' => '/physical_files/processed_but_no_file',
    'Files for specific userid' => '/physical_files/files_for_specific_userid',
    'Waiting to be processed' => '/physical_files/waiting_to_be_processed'
  }

  SKILLS = ["Learning","Straight Forward Forms", "Complicated Forms", "Post 1700 modern freehand", "Post 1530 freehand - Secretary",  "Post 1530 freehand - Latin", "Post 1530 freehand - Latin & Chancery" ]

  REASONS_FOR_INACTIVATING = {
    'Not currently transcribing (may return)' => 'temporary',
    'No longer transcribing (permanently)' => 'permanent',
    'Emails bounce' => 'bad-email',
    'No response to contact over time' => 'no-response',
    'Deceased' => 'deceased',
    'Requested no further contact' => 'do-not-contact',
    'Coordinator controlled' => 'coord-controlled',
    'Other (please explain below)' => 'other'
  }

  REASONS_FOR_MAKING_EMAIL_INVALID = ["Mails to this email bounced", "No Response", "Cannot be reached"]
end
