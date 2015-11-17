module UseridRole
  VALUES = ["researcher","trainee",'pending', 'transcriber','syndicate_coordinator','county_coordinator','country_coordinator',
            'volunteer_coordinator','data_manager', 'technical','system_administrator', 'contacts_coordinator']
  OPTIONS = {
    'researcher' => [ "Profile","Roadmap"],
    'trainee' => [ "Profile", "Batches","Roadmap"],
    'pending' => [ "Profile"],
    'transcriber' => [  "Profile", "Batches","Roadmap"],
    'syndicate_coordinator' => [  "Profile", "Batches", "Manage Syndicate","Roadmap"],
    'contacts_coordinator'=> [ "Profile", "Batches", "Feedback", "Contacts"],
    'county_coordinator' =>  [  "Profile", "Batches", "Manage Syndicate", "Manage County", "Access Profiles","Contacts","Roadmap"],
    'country_coordinator' => [  "Profile", "Batches", "Manage Syndicate","Manage Country", "Manage County","Access Profiles","Contacts","Roadmap"],
    'volunteer_coordinator' => [  "Profile", "Batches", "Manage Syndicates", "Manage Userids","Contacts","Roadmap"],
    'data_manager' => [  "Profile", "Batches", "Manage Syndicate", "Manage Counties", "Access Profiles", "RefineryCMS", "Physical Files","Access Attic", "Search Performance",
                         "Feedback", "Contacts", "System Documentation" ],
    'technical' => [  "Profile", "Batches",   "RefineryCMS", "Access Attic","Search Performance", "Feedback", "Contacts", "Site Statistics",
                      "System Documentation" ,"Logout"],
    'system_administrator' =>[  "Profile", "Batches", "Manage Syndicate", "Manage Counties", "Manage Userids", "Syndicate Coordinators",
                                "County Coordinators", "Country Coordinators","Physical Files","RefineryCMS", "Access Attic","Site Statistics","Search Performance",
                                "Feedback", "Contacts", "System Documentation" ]
  }

  OPTIONS_TRANSLATION = {
    "Saved Searches" => "/my_saved_searches",
    "Profile" => "/userid_details/my_own" ,
    "Batches" => "/freereg1_csv_files/my_own" ,
    "Manage Syndicate" =>  "/manage_syndicates",
    "Manage Syndicates" =>  "/manage_syndicates",
    "Manage County" => "/manage_counties" ,
    "Manage Country" => "/manage_counties" ,
    "Manage Counties" => "/manage_counties" ,
    "Manage Userids"=> "/userid_details/options" ,
    "Access Profiles" => "/userid_details/display" ,
    "Syndicate Coordinators" => "/syndicates" ,
    "County Coordinators" => "/counties" ,
    "Country Coordinators" => "/countries" ,
    "Upload New Batch"  =>   "/csvfiles/new", #"/manage_counties/selection?option=Upload New Batch",
    "RefineryCMS" =>  "/refinery",
    "Access Attic" => "/attic_files/select" ,
    "Physical Files" => "/physical_files/select_action",
    "Site Statistics" => "/site_statistics",
    "Search Performance" => "/search_queries/report" ,
    "Feedback" => "/feedbacks",
    "Contacts" => "/contacts",
    "System Documentation" => "../system-documents",
    "Roadmap" => "../system-documents/development-roadmap",
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
                               'Review Batches by Most Recent Date of Change',  'Review Batches by Oldest Date of Change','Review Specific Batch',"Upload New Batch"]
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
    'Review Specific Batch'=> "/manage_counties/selection?option=Review Specific Batch",
    'Upload New Batch' =>  "/csvfiles/new"
  }
  SYNDICATE_MANAGEMENT_OPTIONS =  ['Review Active Members' ,'Review All Members', 'Select Specific Member by Userid',
                                   'Select Specific Member by Email Address','Select Specific Member by Surname/Forename',"Create userid",'Review Batches with Errors','Review Batches by Filename',
                                   'Review Batches by Userid then Filename', 'Review Batches by Most Recent Date of Change','Review Batches by Oldest Date of Change',
                                   'Review Specific Batch','List files waiting to be processed',"Upload New Batch",'Change Recruiting Status']
  SYNDICATE_OPTIONS_TRANSLATION = {
    'Review Active Members' => "/manage_syndicates/selection?option=Review Active Members",
    'Review All Members'=> "/manage_syndicates/selection?option=Review All Members",
    'Select Specific Member by Userid'=> "/manage_syndicates/selection?option=Select Specific Member by Userid",
    'Select Specific Member by Email Address'=> "/manage_syndicates/selection?option=Select Specific Member by Email Address",
    'Select Specific Member by Surname/Forename' => "/manage_syndicates/selection?option=Select Specific Member by Surname/Forename",
    "Create userid"=> "/userid_details/selection?option=Create userid",
    'Review Batches with Errors'=> "/manage_syndicates/selection?option=Review Batches with Errors",
    'Review Batches by Filename' => "/manage_syndicates/selection?option=Review Batches by Filename",
    'Upload New Batch'=> "/manage_syndicates/selection?option=Upload New Batch",
    'Review Batches by Userid then Filename' => "/manage_syndicates/selection?option=Review Batches by Userid then Filename",
    'Review Batches by Most Recent Date of Change' => "/manage_syndicates/selection?option=Review Batches by Most Recent Date of Change",
    'Review Batches by Oldest Date of Change' => "/manage_syndicates/selection?option=Review Batches by Oldest Date of Change",
    'Review Specific Batch'=> "/manage_syndicates/selection?option=Review Specific Batch",
    'Upload New Batch' =>  "/csvfiles/new",
    'List files waiting to be processed'  => "/manage_syndicates/display_files_waiting_to_be_processed",
    'Change Recruiting Status' => "/manage_syndicates/selection?option=Change Recruiting Status"
  }
  PHYSICAL_FILES_OPTIONS =  ['Files Not Processed','Processed but no Files','Processed but no File in FR1','Processed but no File in FR2','Browse Files' ,
                             'Waiting to be processed','Files for Specific Userid' ]

  PHYSICAL_FILES_OPTIONS_TRANSLATION ={
    'Browse Files' => "/physical_files/all_files",
    'Files Not Processed' => '/physical_files/file_not_processed',
    'Processed but no File in FR2' => '/physical_files/processed_but_no_file_in_fr2',
    'Processed but no File in FR1' => '/physical_files/processed_but_no_file_in_fr1',
    'Processed but no Files' => '/physical_files/processed_but_no_files',
    'Waiting to be processed' => '/physical_files/waiting_to_be_processed',
    'Files for Specific Userid' => '/physical_files/files_for_specific_userid',
  }




  SKILLS = ["Learning","Straight Forward Forms", "Complicated Forms", "Post 1700 modern freehand", "Post 1530 freehand - Secretary",  "Post 1530 freehand - Latin", "Post 1530 freehand - Latin & Chancery" ]

# Remove options for functionality that is not implemented for FreeCen yet
  if MyopicVicar::Application.config.template_set == 'freecen'
    OPTIONS.each do |role,opts|
      if opts.include?('Batches')
        opts.delete("Batches")
      end
      if opts.include?('Access Attic')
        opts.delete("Access Attic")
      end
      if opts.include?('Physical Files')
        opts.delete("Physical Files")
      end
    end
    self.send(:remove_const, :FILE_MANAGEMENT_OPTIONS)
    FILE_MANAGEMENT_OPTIONS = []
    COUNTY_MANAGEMENT_OPTIONS.reverse_each do |val|
      unless val.downcase().index("batch").nil?
        COUNTY_MANAGEMENT_OPTIONS.delete(val)
      end
    end

    SYNDICATE_MANAGEMENT_OPTIONS.reverse_each do |val|
      unless val.downcase().index("batch").nil?
        SYNDICATE_MANAGEMENT_OPTIONS.delete(val)
      end
    end

    self.send(:remove_const, :PHYSICAL_FILES_OPTIONS)
    PHYSICAL_FILES_OPTIONS = []
  end

end
