module UseridRole
  VALUES = ['researcher','trainee','pending', 'transcriber','syndicate_coordinator','county_coordinator','country_coordinator',
    'volunteer_coordinator','data_manager', 'technical','system_administrator']
    OPTIONS = {'researcher' => ["Saved Searches", "Profile", "Help","Logout"], 
      'trainee' => ["Saved Searches", "Profile", "Files","Help", "Logout"],
      'pending' => ["Saved Searches", "Profile", "Help", "Logout"],
      'transcriber' => ["Saved Searches", "Profile", "Files" , "Help", "Logout"],
      'syndicate_coordinator' => ["Saved Searches", "Profile", "Files", "Manage Syndicate",  "Help", "Logout"],
      'county_coordinator' =>  ["Saved Searches", "Profile", "Files", "Manage County",  "Help", "Logout"],
      'country_coordinator' => ["Saved Searches", "Profile", "Files", "Manage Syndicate", "Manage County" "Help", "Logout"],
      'volunteer_coordinator' => ["Saved Searches", "Profile", "Files", "Manage Syndicates", "Manage Userids",  "Help", "Logout"],
      'data_manager' => ["Saved Searches", "Profile", "Files", "Manage Counties", "Access Userids",  "Help", "Logout"],
      'technical' => ["Saved Searches", "Profile", "Files", "RefineryCMS", "Access Attic","Search Performance", "Feedback",
        "Help", "Logout"],
        'system_administrator' =>["Saved Searches", "Profile", "Files","Manage Syndicate", "Manage Counties", "Manage Userids", "Syndicate Coordinators", 
          "County Coordinators", "Country Coordinators","RefineryCMS", "Access Attic","Search Performance", "Feedback",  "Help", "Logout"]
        }
        
        OPTIONS_TRANSLATION = {"Saved Searches" => "/my_saved_searches",
          "Profile" => "/userid_details/my_own" ,
          "Files" => "/freereg1_csv_files/my_own" ,
          "Manage Syndicate" =>  "/manage_syndicates?option=mine",
          "Manage Syndicates" =>  "/manage_syndicates?option=all",
          "Manage County" => "/manage_counties?option=mine" ,
          "Manage Counties" => "/manage_counties?option=all" ,
          "Manage Userids"=> "/userid_details/options?option=manager" ,
          "Access Userids" => "/userid_details/select?option=access" , 
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
        SKILLS = ["Learning","Straight Forward Forms", "Complicated Forms", "Post 1700 modern freehand", "Post 1530 freehand - Secretary",  "Post 1530 freehand - Latin", "Post 1530 freehand - Latin & Chancery" ]

      end