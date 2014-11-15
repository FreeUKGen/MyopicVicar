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
      'data_manager' => ["Saved Searches", "Profile", "Files", "Manage Counties",  "Help"],
      'technical' => ["Saved Searches", "Profile", "Files", "RefineryCMS", "Access Attic","Search Performance", "Feedback",
        "Help", "Logout"],
        'system_administrator' =>["Saved Searches", "Profile", "Files","Manage Syndicate", "Manage Counties", "Manage Userids", "Syndicate Coordinators", 
          "County Coordinators", "Country Coordinators","RefineryCMS", "Access Attic","Search Performance", "Feedback",  "Help"]
        }
        
        OPTIONS_TRANSLATION = {"Saved Searches" => "/my_saved_searches",
          "Profile" => "/userid_details/my_own" ,
          "Files" => "/freereg1_csv_files/my_own" ,
          "Manage Syndicate" =>  "/manage_syndicates?option=mine",
          "Manage Syndicates" =>  "/manage_syndicates?option=all",
          "Manage County" => "/manage_counties?option=mine" ,
          "Manage Country" => "/manage_counties?option=mine" ,
          "Manage Counties" => "/manage_counties?option=all" ,
          "Manage Userids"=> "/userid_details/options?option=manager" ,
          "Access Userids" => "/userid_details/options?option=access" , 
          "Syndicate Coordinators" => "/syndicates?option=manager" ,      
          "County Coordinators" => "/counties?option=manager" ,
          "Country Coordinators" => "/countries?option=manager" ,
          "RefineryCMS" =>  "/refinery",
          "Access Attic" => "/attic/select?option=manager" ,
          "Search Performance" => "/search_queries/report" ,
          "Feedback" => "/feedbacks",
          "Help" => "/information-for-transcribers" ,
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
        FILE_MANAGEMENT_OPTIONS = ['Upload New Batch','List by number of errors then name', 'List by name', 'List by uploaded date (ascending)', 'List by uploaded date (descending)' ]
        FILE_OPTIONS_TRANSLATION ={
        'Upload New Batch' =>  "/csvfiles/new",
        'List by number of errors then name' =>  "/freereg1_csv_files/selection?option=List by number of errors then name",
        'List by name' =>  "/freereg1_csv_files/selection?option=List by name",
        'List by uploaded date (ascending)' =>  "/freereg1_csv_files/selection?option=List by uploaded date (ascending)",
        'List by uploaded date (descending)'  =>  "/freereg1_csv_files/selection?option=List by uploaded date (descending)"
        }
        COUNTY_MANAGEMENT_OPTIONS = ['Work with All Places', 'Work with Active Places','Review Batches with errors',
          'Review Batches listed by filename', 'Upload New Batch', 'Review Batches listed by userid then filename',
          'Review Batches listed by descending date', 'Review Batches listed by ascending date','Review a specific Batch']
        COUNTY_OPTIONS_TRANSLATION = {
          'Work with All Places' => "/manage_counties/selection?option=Work with All Places",
          'Work with Active Places' => "/manage_counties/selection?option=Work with Active Places",
          'Review Batches with errors' => "/manage_counties/selection?option=Review Batches with errors",
          'Review Batches listed by filename' => "/manage_counties/selection?option=Review Batches listed by filename",
          'Upload New Batch'  => "/manage_counties/selection?option=Upload New Batch",
          'Review Batches listed by userid then filename' => "/manage_counties/selection?option=Review Batches listed by userid then filename",
          'Review Batches listed by descending date' => "/manage_counties/selection?option=Review Batches listed by descending date",
          'Review Batches listed by ascending date' => "/manage_counties/selection?option=Review Batches listed by ascending date",
          'Review a specific Batch'=> "/manage_counties/selection?option=Review a specific Batch"
        }





        SKILLS = ["Learning","Straight Forward Forms", "Complicated Forms", "Post 1700 modern freehand", "Post 1530 freehand - Secretary",  "Post 1530 freehand - Latin", "Post 1530 freehand - Latin & Chancery" ]

      end