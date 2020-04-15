module UseridRole
  VALUES = ['checker', 'computer', 'contacts_coordinator', 'county_coordinator', 'country_coordinator', 'data_manager', 'documentation_coordinator',
            'engagement_coordinator', 'executive_director', 'genealogy_coordinator', 'general_communication_coordinator', 'pending', 'project_manager',
            'publicity_coordinator', 'researcher', 'syndicate_coordinator', 'system_administrator', 'technical', 'trainee', 'transcriber',
            'validator', 'volunteer_coordinator', 'website_coordinator']
  case MyopicVicar::Application.config.template_set
  when 'freereg'
    OPTIONS = {
      'researcher' => ['Communicate', 'Profile', 'Roadmap', 'FreeUKGenealogy  Policies'],
      'computer' => ['Profile', 'Roadmap'],
      'trainee' => ['Assignments', 'Batches', 'Communicate', 'Profile', 'Batches', 'Roadmap', 'FreeUKGenealogy  Policies'],
      'pending' => ['Profile'],
      'transcriber' => ['Assignments', 'Batches', 'Communicate', 'Profile', 'Roadmap', 'FreeUKGenealogy  Policies'],
      'syndicate_coordinator' => ['Assignments', 'Batches', 'Communicate', 'Manage Syndicate', 'Profile', 'Roadmap', 'FreeUKGenealogy  Policies'],
      'contacts_coordinator' => ['Assignments', 'Batches', 'Communicate', 'Contacts', 'Display County Coordinators',
                                 'Display Syndicate Coordinators', 'Display Userids', 'Feedback', 'Manage Counties', 'Profile', 'System Documentation', 'Roadmap', 'FreeUKGenealogy  Policies'],
      'county_coordinator' => ['Assignments', 'Batches', 'Communicate', 'Contacts',  'Display Userids', 'Manage County', 'Manage Syndicate', 'Profile', 'Roadmap', 'FreeUKGenealogy  Policies'],
      'country_coordinator' => ['Assignments', 'Batches', 'Communicate', 'Contacts', 'Display Userids', 'Manage County', 'Manage Syndicate', 'Profile', 'Roadmap', 'FreeUKGenealogy  Policies'],
      'volunteer_coordinator' => ['Assignments', 'Batches', 'Communicate', 'Contacts', 'Manage Syndicates', 'Manage Userids', 'Profile', 'Roadmap', 'FreeUKGenealogy  Policies'],
      'data_manager' => ['Access Attic', 'Assignments', 'Batches', 'Communicate', 'Contacts', 'Denominations', 'Display Userids', 'Display Syndicate Coordinators', 'Display County Coordinators', 'Manage Counties', 'Manage Syndicates', 'Physical Files', 'Profile', 'Roadmap' ],
      'technical' => ['Access Attic', 'Assignments', 'Batches', 'Communicate', 'Manage Assignments', 'Contacts', 'Feedback', 'Profile', 'RefineryCMS', 'Roadmap', 'Search Performance', 'Site Statistics',
                      'System Documentation', 'FreeUKGenealogy  Policies'],
      'system_administrator' => ['Access Attic', 'Assignments', 'Batches', 'Communicate', 'Contacts', 'County Coordinators', 'Country Coordinators', 'Denominations', 'GAP Reasons', 'Feedback',
                                 'Manage Counties', 'Manage Image Server', 'Manage Syndicates', 'Manage Userids', 'Message System',  'Physical Files', 'Profile', 'RefineryCMS', 'Roadmap', 'Search Performance', 'Site Statistics',
                                 'Software Version Information', 'Syndicate Coordinators', 'System Documentation', 'FreeUKGenealogy  Policies'],
      'project_manager' => ['Assignments', 'Batches', 'Communicate', 'Contacts', 'Manage Userids', 'Feedback', 'Profile', 'RefineryCMS', 'Roadmap', 'Search Performance', 'Site Statistics',
                            'System Documentation', 'FreeUKGenealogy  Policies'],
      'executive_director' => ['Assignments', 'Batches', 'Communicate', 'Contacts', 'County Coordinators', 'Country Coordinators',
                               'Feedback', 'Profile', 'Manage Userids', 'Message System', 'RefineryCMS', 'Roadmap',
                               'Site Statistics', 'Search Performance', 'Syndicate Coordinators', 'System Documentation', 'FreeUKGenealogy  Policies'],
      'publicity_coordinator' => ['Assignments', 'Batches', 'Communicate', 'Contacts', 'Profile', 'Roadmap', 'System Documentation', 'FreeUKGenealogy  Policies'],
      'genealogy_coordinator' => ['Assignments', 'Batches', 'Communicate', 'Contacts', 'Profile', 'Roadmap', 'System Documentation', 'FreeUKGenealogy  Policies'],
      'documentation_coordinator' => ['Assignments', 'Batches', 'Communicate', 'Display Userids', 'Feedback', 'Manage Syndicates',
                                      'Manage Counties', 'Profile', 'RefineryCMS', 'Roadmap', 'System Documentation', 'FreeUKGenealogy  Policies'],
      'engagement_coordinator' => ['Assignments', 'Batches', 'Communicate', 'Contacts', 'Manage Userids', 'Feedback', 'Message System', 'Profile', 'RefineryCMS', 'Roadmap', 'System Documentation', 'FreeUKGenealogy  Policies'],
      'website_coordinator' => ['Batches', 'Contacts', 'Communicate', 'Display Userids', 'Feedback', 'Message System', 'Profile', 'RefineryCMS', 'Roadmap', 'System Documentation', 'FreeUKGenealogy  Policies'],
      'general_communication_coordinator' => ['Batches', 'Contacts', 'Communicate', 'Display Userids', 'Feedback', 'Message System', 'Profile', 'RefineryCMS', 'Roadmap', 'System Documentation', 'FreeUKGenealogy  Policies']
    }
  when 'freecen'
    OPTIONS = {
      'checker' => ['Communicate', 'Profile', 'Roadmap', 'FreeUKGenealogy  Policies'],
      'computer' => ['Profile', 'Roadmap', 'FreeUKGenealogy  Policies'],
      'researcher' => ['Communicate', 'Profile', 'Roadmap', 'FreeUKGenealogy  Policies'],
      'pending' => ['Profile', 'FreeUKGenealogy  Policies'],
      'contacts_coordinator' => ['Communicate', 'Contacts', 'Display County Coordinators',
                                 'Display Syndicate Coordinators', 'Display Userids', 'Feedback', 'Manage Counties', 'Profile', 'System Documentation', 'Roadmap', 'FreeUKGenealogy  Policies'],
      'county_coordinator' => ['Communicate', 'Contacts', 'Display Userids', 'Manage County', 'Manage Syndicate', 'Profile', 'Roadmap', 'FreeUKGenealogy  Policies', 'FreeUKGenealogy  Policies'],
      'data_manager' => ['Communicate', 'Contacts', 'Database Statistics', 'Display Userids', 'Display Syndicate Coordinators', 'Display County Coordinators', 'Manage Counties', 'Manage Syndicates', 'Profile', 'Roadmap', 'FreeUKGenealogy  Policies' ],
      'documentation_coordinator' => ['Communicate', 'Display Userids', 'Feedback', 'Manage Syndicates',
                                      'Manage Counties', 'Profile', 'RefineryCMS', 'Roadmap', 'System Documentation', 'FreeUKGenealogy  Policies'],
      'engagement_coordinator' => ['Communicate', 'Contacts', 'Database Statistics', 'Manage Userids', 'Feedback', 'Message System', 'Profile', 'RefineryCMS', 'Roadmap', 'System Documentation', 'FreeUKGenealogy  Policies'],

      'executive_director' => ['Communicate', 'Contacts', 'County Coordinators', 'Country Coordinators', 'Database Statistics',
                               'Feedback', 'FreeCen Errors', 'Profile', 'Manage FreeCen Coverage', 'Manage Userids', 'Message System', 'RefineryCMS', 'Roadmap',
                               'Site Statistics', 'Search Performance', 'Syndicate Coordinators', 'System Documentation', 'FreeUKGenealogy  Policies'],
      'genealogy_coordinator' => ['Communicate', 'Contacts', 'Profile', 'Roadmap', 'System Documentation', 'FreeUKGenealogy  Policies'],
      'general_communication_coordinator' => ['Communicate', 'Display Userids', 'Feedback', 'Message System', 'Profile', 'RefineryCMS', 'Roadmap', 'System Documentation', 'FreeUKGenealogy  Policies'],

      'project_manager' => ['Communicate', 'Contacts', 'Database Statistics', 'FreeCen Errors', 'Manage Userids', 'Manage FreeCen Coverage', 'Feedback', 'Profile', 'RefineryCMS', 'Roadmap', 'Search Performance', 'Site Statistics',
                            'System Documentation', 'FreeUKGenealogy  Policies'],
      'publicity_coordinator' => ['Communicate', 'Contacts', 'Profile', 'Roadmap', 'System Documentation', 'FreeUKGenealogy  Policies'],

      'syndicate_coordinator' => ['Communicate', 'Manage Syndicate', 'Profile', 'Roadmap', 'FreeUKGenealogy  Policies'],
      'system_administrator' => ['Communicate', 'Manage Parms', 'Contacts', 'County Coordinators', 'Country Coordinators', 'Database Statistics', 'Feedback', 'FreeCen Errors',
                                 'Manage Counties', 'Manage FreeCen Coverage', 'Manage Syndicates', 'Manage Userids', 'Message System', 'Profile', 'RefineryCMS', 'Roadmap', 'Search Performance', 'Site Statistics',
                                 'Software Version Information', 'Syndicate Coordinators', 'System Documentation', 'FreeUKGenealogy  Policies'],
      'trainee' => ['Communicate', 'Profile', 'Roadmap', 'FreeUKGenealogy  Policies'],
      'technical' => ['Communicate', 'Contacts', 'Database Statistics', 'Feedback', 'FreeCen Errors', 'Profile', 'RefineryCMS', 'Roadmap', 'Search Performance', 'Site Statistics',
                      'System Documentation', 'FreeUKGenealogy  Policies'],

      'transcriber' => ['Communicate', 'Profile', 'Roadmap', 'FreeUKGenealogy  Policies'],
      'validator' => ['Communicate', 'Profile', 'Roadmap', 'FreeUKGenealogy  Policies'],
      'volunteer_coordinator' => ['Communicate', 'Contacts', 'Manage Syndicates', 'Manage Userids', 'Profile', 'Roadmap', 'FreeUKGenealogy  Policies'],
      'website_coordinator' => ['Communicate', 'Contacts', 'Database Statistics', 'Display Userids', 'Feedback', 'Message System', 'Profile', 'RefineryCMS', 'Roadmap', 'System Documentation', 'FreeUKGenealogy  Policies']

    }
  end
  #'/messages/communications?source=original',
  OPTIONS_TRANSLATION = {
    'Communicate' => '/messages/communications?source=original',
    'Denominations' => '/denominations',
    'Database Statistics' => '/freecen_coverage/grand_totals',
    'GAP Reasons' => '/gap_reasons',
    'Saved Searches' => '/my_saved_searches',
    'Profile' => '/userid_details/my_own',
    'Batches' => '/freereg1_csv_files/my_own',
    'Manage Syndicate' => '/manage_syndicates',
    'Manage Syndicates' => '/manage_syndicates',
    'Manage Parms' => '/manage_parms/select_year',
    'Manage County' => '/manage_counties',
    'Manage Counties' => '/manage_counties',
    'Manage Image Server' => '/sources/access_image_server',
    'Manage Userids' => '/userid_details/options',
    'Display Userids' => '/userid_details/display',
    'Display Syndicate Coordinators' => '/syndicates/display',
    'Display County Coordinators' => '/counties/display',
    'Syndicate Coordinators' => '/syndicates',
    'County Coordinators' => '/counties',
    'Country Coordinators' => '/countries',
    'Upload New Batch' => '/csvfiles/new',
    'RefineryCMS' => '/manage_resources/pages',
    'Access Attic' => '/attic_files/select_userid',
    'Physical Files' => '/physical_files/select_action',
    'Site Statistics' => '/site_statistics',
    'Search Performance' => '/search_queries/report',
    'Software Version Information' => '/software_versions/select_app_and_server',
    'Feedback' => '/feedbacks',
    'Contacts' => '/contacts',
    'System Documentation' => '/cms/system-documents',
    'Roadmap' => '/cms/system-documents/development-roadmap',
    'Logout' => '/refinery/logout',
    'Message System' => '/messages',
    'Manage Images' => '/sources',
    'Assignments' => '/assignments/my_own',
    'Manage Pieces' => '/freecen_pieces',
    'FreeCen Errors' => '/freecen_errors',
    'Manage FreeCen Coverage' => '/freecen_coverage/edit',
    'FreeUKGenealogy  Policies' => '/cms/freeukgenealogy-policies'
  }
  USERID_MANAGER_OPTIONS = ['Select specific userid', 'Select specific email', 'Select specific surname/forename',
                            'Browse userids', 'Select Role', 'Select Secondary Role', 'Transcription Agreement Accepted',
                            'Transcription Agreement Not Accepted', 'Incomplete Registrations', 'Create userid', 'Transcriber Statistics']
  USERID_ACCESS_OPTIONS = ['Select specific userid', 'Select specific email', 'Select specific surname/forename']

  USERID_OPTIONS_TRANSLATION = {
    # todo clean up first 2
    'Browse userids' => '/userid_details/selection?option=Browse userids',
    'Incomplete Registrations' => '/userid_details/incomplete_registrations',
    'Create userid' => '/userid_details/selection?option=Create userid',
    'Select specific email' => '/userid_details/selection?option=Select specific email',
    'Select specific userid' => '/userid_details/selection?option=Select specific userid',
    'Select specific surname/forename' => '/userid_details/selection?option=Select specific surname/forename',
    'Select Role' => '/userid_details/person_roles',
    'Select Secondary Role' => '/userid_details/secondary_roles',
    'Transcriber Statistics' => '/userid_details/transcriber_statistics',
    'Transcription Agreement Accepted' => '/manage_syndicates/selection?option=Transcription Agreement Accepted',
    'Transcription Agreement Not Accepted' => '/manage_syndicates/selection?option=Transcription Agreement Not Accepted'
  }
  FILE_MANAGEMENT_OPTIONS = ['Upload New Batch', 'List by Number of Errors then Filename', 'List those with Zero Dates', 'List by Filename',
                             'List by uploaded date (ascending)', 'List by uploaded date (descending)', 'List files waiting to be processed', 'Review Specific Batch']
  FILE_OPTIONS_TRANSLATION ={
    'Upload New Batch' => '/csvfiles/new',
    'List by Number of Errors then Filename' => '/freereg1_csv_files/selection?option=List by Number of Errors then Filename',
    'List those with Zero Dates' => '/freereg1_csv_files/selection?option=Review Batches with Zero Dates',
    'List by Filename' => '/freereg1_csv_files/selection?option=List by Filename',
    'List by uploaded date (ascending)' => '/freereg1_csv_files/selection?option=List by uploaded date (ascending)',
    'List by uploaded date (descending)' => '/freereg1_csv_files/selection?option=List by uploaded date (descending)',
    'List files waiting to be processed' => '/freereg1_csv_files/selection?option=List files waiting to be processed',
    'Review Specific Batch' => '/freereg1_csv_files/selection?option=Review Specific Batch'
  }
  case MyopicVicar::Application.config.template_set
  when 'freereg'
    COUNTY_MANAGEMENT_OPTIONS = ['All Places', 'Active Places', 'Specific Place', 'Places with Unapproved Names', 'Review Batches with Errors',
                                 'Review Batches with Zero Dates', 'Review Batches by Filename', 'Review Batches by Userid then Filename',
                                 'Review Batches by Most Recent Date of Change', 'Review Batches by Oldest Date of Change', 'Review Specific Batch',
                                 'Upload New Batch', 'Offline Reports', 'Manage Images']
  when 'freecen'
    COUNTY_MANAGEMENT_OPTIONS = ['Manage Pieces', 'Manage VLD Files', 'Manage Places']
  when 'freebmd'
  end
  COUNTY_OPTIONS_TRANSLATION = {
    'All Places' => '/manage_counties/selection?option=Work with All Places',
    'Active Places' => '/manage_counties/selection?option=Work with Active Places',
    'Specific Place' => '/manage_counties/selection?option=Work with Specific Place',
    'Places with Unapproved Names' => '/manage_counties/selection?option=Places with Unapproved Names',
    'Review Batches with Errors' => '/manage_counties/selection?option=Review Batches with Errors',
    'Review Batches with Zero Dates' => '/manage_counties/selection?option=Review Batches with Zero Dates',
    'Review Batches by Filename' => '/manage_counties/selection?option=Review Batches by Filename',
    'Review Batches by Userid then Filename' => '/manage_counties/selection?option=Review Batches by Userid then Filename',
    'Review Batches by Most Recent Date of Change' => '/manage_counties/selection?option=Review Batches by Most Recent Date of Change',
    'Review Batches by Oldest Date of Change' => '/manage_counties/selection?option=Review Batches by Oldest Date of Change',
    'Review Specific Batch' => '/manage_counties/selection?option=Review Specific Batch',
    'Upload New Batch' => '/csvfiles/new',
    'Manage Images' => '/manage_counties/selection?option=Manage Images',
    'Manage Pieces' => '/freecen_pieces',
    'Manage VLD Files' => '/freecen1_vld_files',
    'Manage Places' => '/places',
    'Offline Reports' => '/manage_counties/selection?option=Offline Reports'

  }
  SYNDICATE_MANAGEMENT_OPTIONS =  ['Review Active Members', 'Review All Members', 'Transcription Agreement Accepted', 'Transcription Agreement Not Accepted', 'Select Specific Member by Userid',
                                   'Select Specific Member by Email Address', 'Select Specific Member by Surname/Forename', 'Incomplete Registrations', 'Create Userid',
                                   'Syndicate Messages', 'Review Batches with Errors', 'Review Batches with Zero Dates', 'Review Batches by Filename',
                                   'Review Batches by Userid then Filename', 'Review Batches by Most Recent Date of Change', 'Review Batches by Oldest Date of Change',
                                   'Review Specific Batch', 'List files waiting to be processed', 'List files NOT processed', 'Upload New Batch', 'Change Recruiting Status', 'Manage Images']
  SYNDICATE_OPTIONS_TRANSLATION = {
    'Review Active Members' => '/manage_syndicates/selection?option=Review Active Members',
    'Review All Members' => '/manage_syndicates/selection?option=Review All Members',
    'Transcription Agreement Accepted' => '/manage_syndicates/selection?option=Transcription Agreement Accepted',
    'Transcription Agreement Not Accepted' => '/manage_syndicates/selection?option=Transcription Agreement Not Accepted',
    'Select Specific Member by Userid' => '/manage_syndicates/selection?option=Select Specific Member by Userid',
    'Select Specific Member by Email Address' => '/manage_syndicates/selection?option=Select Specific Member by Email Address',
    'Select Specific Member by Surname/Forename' => '/manage_syndicates/selection?option=Select Specific Member by Surname/Forename',
    'Incomplete Registrations' => '/userid_details/incomplete_registrations',
    'Create Userid' => '/userid_details/selection?option=Create userid',
    'Syndicate Messages' => '/messages/list_syndicate_messages?source=list_syndicate_messages',
    'Review Batches with Errors' => '/manage_syndicates/selection?option=Review Batches with Errors',
    'Review Batches with Zero Dates' => '/manage_syndicates/selection?option=Review Batches with Zero Dates',
    'Review Batches by Filename' => '/manage_syndicates/selection?option=Review Batches by Filename',
    'Review Batches by Userid then Filename' => '/manage_syndicates/selection?option=Review Batches by Userid then Filename',
    'Review Batches by Most Recent Date of Change' => '/manage_syndicates/selection?option=Review Batches by Most Recent Date of Change',
    'Review Batches by Oldest Date of Change' => '/manage_syndicates/selection?option=Review Batches by Oldest Date of Change',
    'Review Specific Batch' => '/manage_syndicates/selection?option=Review Specific Batch',
    'Upload New Batch' => '/csvfiles/new',
    'List files waiting to be processed' => '/manage_syndicates/display_files_waiting_to_be_processed',
    'List files NOT processed' => '/manage_syndicates/display_files_not_processed',
    'Change Recruiting Status' => '/manage_syndicates/selection?option=Change Recruiting Status',
    'Manage Images' => '/manage_syndicates/selection?option=Manage Images'
  }
  PHYSICAL_FILES_OPTIONS = ['Waiting to be processed', 'Files not processed', 'Processed but no file', 'Browse files', 'Files for specific userid']

  PHYSICAL_FILES_OPTIONS_TRANSLATION = {
    'Browse files' => '/physical_files/all_files',
    'Files not processed' => '/physical_files/file_not_processed',
    'Processed but no file' => '/physical_files/processed_but_no_file',
    'Files for specific userid' => '/physical_files/files_for_specific_userid',
    'Waiting to be processed' => '/physical_files/waiting_to_be_processed'
  }

  SKILLS = ['Learning', 'Straight Forward Forms', 'Complicated Forms', 'Post 1700 modern freehand', 'Post 1530 freehand - Secretary', 'Post 1530 freehand - Latin', 'Post 1530 freehand - Latin & Chancery']


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
  REASONS_FOR_MAKING_EMAIL_INVALID = ['Mails to this email bounced', 'No Response', 'Cannot be reached']
end
