module UseridRole
  VALUES = ["researcher","trainee",'pending', 'transcriber','syndicate_coordinator','county_coordinator','country_coordinator',
    'volunteer_coordinator','data_manager', 'technical','system_administrator']
    OPTIONS = {
      'researcher' => [ "Profile"], 
      'trainee' => [ "Profile", "Batches"],
      'pending' => [ "Profile"],
      'transcriber' => [  "Profile", "Batches"],
      'syndicate_coordinator' => [  "Profile", "Batches", "Manage Syndicate"],
      'county_coordinator' =>  [  "Profile", "Batches", "Manage Syndicate", "Manage County", "Access Userids","Contacts"],
      'country_coordinator' => [  "Profile", "Batches", "Manage Syndicate","Manage Country", "Manage County","Access Userids","Contacts"],
      'volunteer_coordinator' => [  "Profile", "Batches", "Manage Syndicates", "Manage Userids","Contacts"],
      'data_manager' => [  "Profile", "Batches", "Manage Syndicate", "Manage Counties", "Access Attic", "Feedback", "Contacts", "System Documentation" ],
      'technical' => [  "Profile", "Batches",   "RefineryCMS", "Access Attic","Search Performance", "Feedback", "Contacts", 
        "System Documentation" ,"Logout"],
      'system_administrator' =>[  "Profile", "Batches", "Manage Syndicate", "Manage Counties", "Manage Userids", "Syndicate Coordinators", 
          "County Coordinators", "Country Coordinators","Physical Files","RefineryCMS", "Access Attic","Search Performance", "Feedback", "Contacts", "System Documentation" ]
      }
        
        OPTIONS_TRANSLATION = {"Saved Searches" => "/my_saved_searches",
          "Profile" => "/userid_details/my_own" ,
          "Batches" => "/freereg1_csv_files/my_own" ,
          "Manage Syndicate" =>  "/manage_syndicates",
          "Manage Syndicates" =>  "/manage_syndicates",
          "Manage County" => "/manage_counties" ,
          "Manage Country" => "/manage_counties" ,
          "Manage Counties" => "/manage_counties" ,
          "Manage Userids"=> "/userid_details/options" ,
          "Access Userids" => "/userid_details/options" , 
          "Syndicate Coordinators" => "/syndicates" ,      
          "County Coordinators" => "/counties" ,
          "Country Coordinators" => "/countries" ,
          "Upload New Batch"  => "/manage_counties/selection?option=Upload New Batch",
          "RefineryCMS" =>  "/refinery",
          "Access Attic" => "/attic_files/select" ,
          "Physical Files" => "/physical_files/select_action",
          "Search Performance" => "/search_queries/report" ,
          "Feedback" => "/feedbacks",
          "Contacts" => "/contacts",
          "System Documentation" => "/system-documents",
          "Logout" => "/refinery/logout"
        }
        USERID_MANAGER_OPTIONS = ["Browse userids","Create userid","Select specific email","Select specific userid", "Select specific surname/forename"]
        USERID_ACCESS_OPTIONS = ["Select specific email","Select specific userid", "Select specific surname/forename"]
        
        USERID_OPTIONS_TRANSLATION = {
          #todo clean up first 2
        "Browse userids" => "/userid_details/selection?option=Browse userids",
        "Create userid"=> "/userid_details/selection?option=Create userid",
        "Select specific email" =>  "/userid_details/selection?option=Select specific email",
        "Select specific userid"=> "/userid_details/selection?option=Select specific userid",
        "Select specific surname/forename"=> "/userid_details/selection?option=Select specific surname/forename" 
        }
        FILE_MANAGEMENT_OPTIONS = ['List by Number of Errors then Filename', 'List by Filename', 'List by uploaded date (ascending)', 'List by uploaded date (descending)', 'Review Specific Batch' ]
        FILE_OPTIONS_TRANSLATION ={
        'Upload New Batch' =>  "/csvfiles/new",
        'List by Number of Errors then Filename' =>  "/freereg1_csv_files/selection?option=List by Number of Errors then Filename",
        'List by Filename' =>  "/freereg1_csv_files/selection?option=List by Filename",
        'List by uploaded date (ascending)' =>  "/freereg1_csv_files/selection?option=List by uploaded date (ascending)",
        'List by uploaded date (descending)'  =>  "/freereg1_csv_files/selection?option=List by uploaded date (descending)",
        'Review Specific Batch' => "/freereg1_csv_files/selection?option=Review Specific Batch"
        }
        COUNTY_MANAGEMENT_OPTIONS = ['All Places', 'Active Places', 'Specific Place','Places with Unapproved Names', 'Review Batches with Errors',
          'Review Batches by Filename', 'Review Batches by Userid then Filename',
          'Review Batches by Most Recent Date of Change',  'Review Batches by Oldest Date of Change','Review Specific Batch']
        COUNTY_OPTIONS_TRANSLATION = {
          'All Places' => "/manage_counties/selection?option=Work with All Places",
          'Active Places' => "/manage_counties/selection?option=Work with Active Places",
          'Specific Place' => "/manage_counties/selection?option=Work with Specific Place",
          'Places with Unapproved Names' => "/manage_counties/selection?option=Places with Unapproved Names",
          'Review Batches with Errors' => "/manage_counties/selection?option=Review Batches with Errors",
          'Review Batches by Filename' => "/manage_counties/selection?option=Review Batches by Filename",
          'Upload New Batch'  => "/manage_counties/selection?option=Upload New Batch",
          'Review Batches by Userid then Filename' => "/manage_counties/selection?option=Review Batches by Userid then Filename",
          'Review Batches by Most Recent Date of Change' => "/manage_counties/selection?option=Review Batches by Most Recent Date of Change",
          'Review Batches by Oldest Date of Change' => "/manage_counties/selection?option=Review Batches by Oldest Date of Change",
          'Review Specific Batch'=> "/manage_counties/selection?option=Review Specific Batch"
        }
        SYNDICATE_MANAGEMENT_OPTIONS =  ['Review Active Members' ,'Review All Members', 'Select Specific Member by Userid',
          'Select Specific Member by Email Address','Select Specific Member by Surname/Forename','Review Batches with Errors','Review Batches by Filename', 
          'Review Batches by Userid then Filename', 'Review Batches by Most Recent Date of Change','Review Batches by Oldest Date of Change',
          'Review Specific Batch', 'Change Recruiting Status']
        SYNDICATE_OPTIONS_TRANSLATION = {
          'Review Active Members' => "/manage_syndicates/selection?option=Review Active Members",
          'Review All Members'=> "/manage_syndicates/selection?option=Review All Members",
          'Select Specific Member by Userid'=> "/manage_syndicates/selection?option=Select Specific Member by Userid",
          'Select Specific Member by Email Address'=> "/manage_syndicates/selection?option=Select Specific Member by Email Address",
          'Select Specific Member by Surname/Forename' => "/manage_syndicates/selection?option=Select Specific Member by Surname/Forename",
          'Review Batches with Errors'=> "/manage_syndicates/selection?option=Review Batches with Errors",
          'Review Batches by Filename' => "/manage_syndicates/selection?option=Review Batches by Filename",
          'Upload New Batch'=> "/manage_syndicates/selection?option=Upload New Batch",
          'Review Batches by Userid then Filename' => "/manage_syndicates/selection?option=Review Batches by Userid then Filename",
          'Review Batches by Most Recent Date of Change' => "/manage_syndicates/selection?option=Review Batches by Most Recent Date of Change",
          'Review Batches by Oldest Date of Change' => "/manage_syndicates/selection?option=Review Batches by Oldest Date of Change",
          'Review Specific Batch'=> "/manage_syndicates/selection?option=Review Specific Batch",
          'Change Recruiting Status' => "/manage_syndicates/selection?option=Change Recruiting Status"
        }
        PHYSICAL_FILES_OPTIONS =  ['Browse Files' ,'List Not Processed', 'List Processed but not in Base Folder',
          'List Processed but not in Change Folder','List Processed but no files','List Files for Userid', 'List Files for Userid Not Processed']
        PHYSICAL_FILES_OPTIONS_TRANSLATION ={
          'Browse Files' => "/physical_files/",
          'List Not Processed' => '/physical_files/not_processed',
          'List Processed but not in Base Folder' => '/physical_files/processed_but_not_in_base',
          'List Processed but not in Change Folder' => '/physical_files/processed_but_not_in_change',
          'List Files for Userid' => '/physical_files/files_for_specific_userid',
          'List Files for Userid Not Processed' => '/physical_files/files_for_specific_userid_not_processed',
          'List Processed but no files' => '/physical_files/processed_but_no_file'
        }


        SKILLS = ["Learning","Straight Forward Forms", "Complicated Forms", "Post 1700 modern freehand", "Post 1530 freehand - Secretary",  "Post 1530 freehand - Latin", "Post 1530 freehand - Latin & Chancery" ]

      end