module UseridRole
  VALUES = ["researcher","trainee",'pending', 'transcriber','syndicate_coordinator','county_coordinator','country_coordinator',
    'volunteer_coordinator','data_manager', 'technical','system_administrator']
    OPTIONS = {'researcher' => ["Saved Searches", "Profile", "Help"], 
      'trainee' => ["Saved Searches", "Profile", "Files","Help"],
      'pending' => ["Saved Searches", "Profile", "Help"],
      'transcriber' => ["Saved Searches", "Profile", "Files", "Help"],
      'syndicate_coordinator' => ["Saved Searches", "Profile", "Files", "Manage Syndicate",  "Help"],
      'county_coordinator' =>  ["Saved Searches", "Profile", "Files", "Manage County", "Access Userids",  "Help"],
      'country_coordinator' => ["Saved Searches", "Profile", "Files", "Manage country", "Manage County","Access Userids", "Help"],
      'volunteer_coordinator' => ["Saved Searches", "Profile", "Files", "Manage Syndicates", "Manage Userids",  "Help"],
      'data_manager' => ["Saved Searches", "Profile", "Files", "Manage Counties",  "System Documentation" , "Help"],
      'technical' => ["Saved Searches", "Profile", "Files", "RefineryCMS", "Access Attic","Search Performance", "Feedback",
        "Help",  "System Documentation" ,"Logout"],
        'system_administrator' =>["Saved Searches", "Profile", "Files","Manage Syndicate", "Manage Counties", "Manage Userids", "Syndicate Coordinators", 
          "County Coordinators", "Country Coordinators","RefineryCMS", "Access Attic","Search Performance", "Feedback",  "System Documentation" , "Help"]
        }
        
        OPTIONS_TRANSLATION = {"Saved Searches" => "/my_saved_searches",
          "Profile" => "/userid_details/my_own" ,
          "Files" => "/freereg1_csv_files/my_own" ,
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
          "RefineryCMS" =>  "/refinery",
          "Access Attic" => "/attic/select" ,
          "Search Performance" => "/search_queries/report" ,
          "Feedback" => "/feedbacks",
          "Help" => "/information-for-transcribers" ,
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
        FILE_MANAGEMENT_OPTIONS = ['Upload New Batch','List by Number of Errors then Filename', 'List by Filename', 'List by uploaded date (ascending)', 'List by uploaded date (descending)' ]
        FILE_OPTIONS_TRANSLATION ={
        'Upload New Batch' =>  "/csvfiles/new",
        'List by Number of Errors then Filename' =>  "/freereg1_csv_files/selection?option=List by Number of Errors then Filename",
        'List by Filename' =>  "/freereg1_csv_files/selection?option=List by Filename",
        'List by uploaded date (ascending)' =>  "/freereg1_csv_files/selection?option=List by uploaded date (ascending)",
        'List by uploaded date (descending)'  =>  "/freereg1_csv_files/selection?option=List by uploaded date (descending)"
        }
        COUNTY_MANAGEMENT_OPTIONS = ['Work with All Places', 'Work with Active Places','Review Batches with Errors',
          'Review Batches by Filename', 'Upload New Batch', 'Review Batches by Userid then Filename',
          'Review Batches by Most Recent Date of Change',  'Review Batches by Oldest Date of Change','Review Specific Batch']
        COUNTY_OPTIONS_TRANSLATION = {
          'Work with All Places' => "/manage_counties/selection?option=Work with All Places",
          'Work with Active Places' => "/manage_counties/selection?option=Work with Active Places",
          'Review Batches with Errors' => "/manage_counties/selection?option=Review Batches with Errors",
          'Review Batches by Filename' => "/manage_counties/selection?option=Review Batches by Filename",
          'Upload New Batch'  => "/manage_counties/selection?option=Upload New Batch",
          'Review Batches by Userid then Filename' => "/manage_counties/selection?option=Review Batches by Userid then Filename",
          'Review Batches by Most Recent Date of Change' => "/manage_counties/selection?option=Review Batches by Most Recent Date of Change",
          'Review Batches by Oldest Date of Change' => "/manage_counties/selection?option=Review Batches by Oldest Date of Change",
          'Review Specific Batch'=> "/manage_counties/selection?option=Review Specific Batch"
        }
        SYNDICATE_MANAGEMENT_OPTIONS =  ['Review Active Members' ,'Review All Members', 'Select Specific Member by Userid',
          'Select Specific Member by Email Address','Select Specific Member by Surname/Forename','Review Batches with Errors','Review Batches by Filename', 'Upload New Batch',
          'Review Batches by Userid then Filename', 'Review Batches by Most Recent Date of Change','Review Batches by Oldest Date of Change',
          'Review Specific Batch']
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
          'Review Specific Batch'=> "/manage_syndicates/selection?option=Review Specific Batch"
        }
     



        SKILLS = ["Learning","Straight Forward Forms", "Complicated Forms", "Post 1700 modern freehand", "Post 1530 freehand - Secretary",  "Post 1530 freehand - Latin", "Post 1530 freehand - Latin & Chancery" ]

      end