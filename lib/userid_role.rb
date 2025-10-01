module UseridRole
  VALUES = ['checker', 'computer', 'contacts_coordinator', 'county_coordinator', 'country_coordinator', 'master_county_coordinator', 'data_manager', 'documentation_coordinator',
            'engagement_coordinator', 'executive_director', 'genealogy_coordinator', 'general_communication_coordinator', 'pending', 'project_manager',
            'publicity_coordinator', 'researcher', 'syndicate_coordinator', 'system_administrator', 'technical', 'trainee', 'transcriber',
            'validator', 'volunteer_coordinator', 'website_coordinator', 'pieces_coordinator', 'image_server_coord']
  case MyopicVicar::Application.config.template_set
  when 'freereg'
    OPTIONS = {
      'researcher' => ['Communicate', 'Profile', 'Coordinators list', 'Roadmap','FreeUKGenealogy  Policies'],
      'computer' => ['Profile', 'Roadmap'],
      'trainee' => ['Assignments', 'Batches', 'Communicate', 'Profile', 'Batches',  'Coordinators list', 'Roadmap', 'FreeUKGenealogy  Policies'],
      'pending' => ['Profile'],
      'transcriber' => ['Assignments', 'Batches', 'Communicate', 'Profile', 'Roadmap', 'Coordinators list', 'FreeUKGenealogy  Policies'],
      'syndicate_coordinator' => ['Assignments', 'Batches', 'Communicate',  'Coordinators list', 'Manage Syndicate', 'Profile', 'Roadmap', 'FreeUKGenealogy  Policies'],
      'contacts_coordinator' => ['Assignments', 'Batches', 'Communicate', 'Contacts', 'Transcriber Statistics', 'Display Communications Coordinators',
                                 'Coordinators list', 'Display Userids', 'Feedback', 'Message System','Manage Counties', 'Profile', 'System Documentation', 'Roadmap', 'FreeUKGenealogy  Policies'],
      'county_coordinator' => ['Assignments', 'Coordinators list', 'Batches', 'Communicate', 'Contacts',  'Display Userids', 'Manage County', 'Manage Syndicate', 'Profile', 'Roadmap', 'FreeUKGenealogy  Policies'],
      'country_coordinator' => ['Assignments', 'Coordinators list', 'Batches', 'Communicate', 'Contacts', 'Display Userids', 'Manage County', 'Manage Syndicate', 'Profile', 'Roadmap', 'FreeUKGenealogy  Policies'],
      'volunteer_coordinator' => ['Assignments', 'Coordinators list', 'Batches', 'Communicate', 'Contacts', 'Manage Syndicates', 'Manage Userids', 'Profile', 'Roadmap', 'FreeUKGenealogy  Policies'],
      'data_manager' => ['Access Attic', 'Assignments', 'Batches', 'Communicate', 'Contacts', 'Denominations', 'Display Userids',  'Coordinators list',
                         'Manage Counties', 'Manage Syndicates', 'Physical Files', 'Profile', 'Roadmap' ],
      'technical' => ['Access Attic', 'Assignments', 'Batches', 'Communicate', 'Coordinators list', 'Manage Assignments', 'Contacts', 'Feedback', 'Profile', 'RefineryCMS', 'Roadmap',  'Search Performance', 'Site Statistics',
                      'System Documentation', 'FreeUKGenealogy  Policies'],
      'system_administrator' => ['Upload Report','Access Attic', 'Assignments', 'Batches', 'Communicate', 'Contacts', 'County Coordinators', 'Country Coordinators', 'Denominations',  'Display Communications Coordinators', 'GAP Reasons', 'Feedback',
                                 'Manage Counties', 'Manage Image Server', 'Manage Syndicates', 'Manage Userids', 'Message System',  'Physical Files', 'Profile', 'RefineryCMS', 'Roadmap',
                                 'Search Performance', 'Site Statistics', 'Coordinators list',
                                 'Software Version Information', 'Syndicate Coordinators', 'System Documentation', 'System Roles', 'FreeUKGenealogy  Policies'],
      'project_manager' => ['Access Attic', 'Assignments', 'Batches', 'Communicate', 'Contacts', 'Coordinators list', 'Country Coordinators', 'Denominations', 'GAP Reasons', 'Feedback',
                            'Manage Counties', 'Manage Image Server', 'Manage Syndicates', 'Manage Userids', 'Message System',  'Physical Files', 'Profile', 'RefineryCMS', 'Roadmap', 'Search Performance', 'Site Statistics',
                            'Software Version Information','System Documentation', 'FreeUKGenealogy  Policies'],
      'executive_director' => ['Upload Report','Access Attic', 'Assignments', 'Batches', 'Communicate', 'Contacts', 'County Coordinators', 'Coordinators list', 'Denominations', 'GAP Reasons', 'Feedback',
                               'Manage Counties', 'Manage Image Server', 'Manage Syndicates', 'Manage Userids', 'Message System',  'Physical Files', 'Profile', 'RefineryCMS', 'Roadmap', 'Search Performance', 'Site Statistics',
                               'Software Version Information', 'System Documentation', 'FreeUKGenealogy  Policies'],
      'publicity_coordinator' => ['Assignments', 'Batches', 'Communicate', 'Contacts', 'Coordinators list', 'Profile', 'Roadmap', 'System Documentation', 'FreeUKGenealogy  Policies'],
      'genealogy_coordinator' => ['Assignments', 'Batches', 'Communicate', 'Contacts', 'Coordinators list', 'Profile', 'Roadmap', 'System Documentation', 'FreeUKGenealogy  Policies'],
      'documentation_coordinator' => ['Assignments', 'Batches', 'Communicate', 'Coordinators list', 'Display Userids', 'Feedback', 'Manage Syndicates',
                                      'Manage Counties', 'Profile', 'RefineryCMS', 'Roadmap', 'System Documentation', 'FreeUKGenealogy  Policies'],
      'engagement_coordinator' => ['Assignments', 'Batches', 'Communicate', 'Contacts', 'Coordinators list', 'Manage Userids', 'Feedback', 'Message System', 'Profile', 'RefineryCMS', 'Site Statistics', 'Roadmap', 'System Documentation', 'FreeUKGenealogy  Policies'],
      'website_coordinator' => ['Batches', 'Contacts', 'Communicate', 'Coordinators list', 'Display Userids', 'Feedback', 'Message System', 'Profile', 'RefineryCMS', 'Roadmap', 'System Documentation', 'FreeUKGenealogy  Policies'],
      'general_communication_coordinator' => ['Batches', 'Contacts', 'Communicate', 'Coordinators list', 'Display Userids', 'Feedback', 'Message System', 'Profile', 'RefineryCMS', 'Roadmap', 'System Documentation', 'FreeUKGenealogy  Policies'],
      'image_server_coord' => ['Profile', 'Coordinators list', 'Image Server','FreeUKGenealogy Policies']
    }
  when 'freecen'
    OPTIONS = {
      'checker' => ['CSV Batches', 'Gazetteer', 'FreeCEN Handbook', 'Communicate', 'Profile', 'Roadmap', 'Display County Coordinators', 'Display Syndicate Coordinators', 'FreeUKGenealogy  Policies'],
      'computer' => ['CSV Batches', 'Profile', 'Roadmap', 'Display County Coordinators', 'Display Syndicate Coordinators',  'FreeUKGenealogy  Policies'],
      'researcher' => ['Communicate', 'Profile', 'Roadmap', 'Display County Coordinators', 'Display Syndicate Coordinators',  'FreeUKGenealogy  Policies'],
      'pending' => ['Profile', 'FreeUKGenealogy  Policies'],
      'contacts_coordinator' => ['CSV Batches', 'Communicate', 'Contacts', 'Display County Coordinators', 'Display Communications Coordinators',
                                 'Display Syndicate Coordinators', 'Display Userids', 'Feedback', 'Gazetteer', 'Manage Counties', 'Profile', 'Transcriber Statistics', 'System Documentation', 'Roadmap', 'FreeCEN Handbook', 'FreeUKGenealogy  Policies'],
      'county_coordinator' => ['CSV Batches', 'Gazetteer', 'Gazetteer CSV Download', 'FreeCEN Handbook', 'Manage Counties', 'Manage Syndicates', 'Site Statistics', 'Contacts', 'Communicate', 'Display Userids', 'Profile',  'Roadmap', 'Display County Coordinators', 'Display Syndicate Coordinators',  'FreeUKGenealogy  Policies'],
      'master_county_coordinator' => ['CSV Batches', 'Gazetteer', 'FreeCEN Handbook', 'Manage Counties', 'Manage Syndicates', 'Site Statistics', 'Contacts', 'Communicate', 'Display Userids', 'Profile',  'Roadmap', 'Display County Coordinators', 'Display Syndicate Coordinators',  'FreeUKGenealogy  Policies'],
      'country_coordinator' => ['CSV Batches', 'Communicate', 'Contacts', 'Display Userids', 'Gazetteer', 'Manage County', 'Manage Syndicate', 'Profile', 'Roadmap', 'FreeCEN Handbook', 'Display County Coordinators', 'Display Syndicate Coordinators',  'FreeUKGenealogy  Policies'],
      'data_manager' => ['CSV Batches', 'Gazetteer', 'FreeCEN Handbook', 'Manage Counties', 'Manage Syndicates', 'Place Edit Reasons', 'Place Sources', 'FreeCen Errors', 'Physical Files', 'Communicate', 'Contacts', 'Database Statistics', 'Access Attic', 'Display Userids', 'Display Syndicate Coordinators', 'Display County Coordinators', 'Profile',
                         'Roadmap', 'FreeUKGenealogy  Policies'],
      'documentation_coordinator' => ['CSV Batches', 'Communicate', 'Display Userids', 'Feedback', 'Gazetteer', 'Manage Syndicates',
                                      'Manage Counties', 'Profile', 'RefineryCMS', 'Roadmap', 'System Documentation', 'FreeCEN Handbook', 'Display County Coordinators', 'Display Syndicate Coordinators',  'FreeUKGenealogy  Policies'],
      'engagement_coordinator' => ['CSV Batches', 'Communicate', 'Contacts', 'Database Statistics', 'Manage Userids', 'Manage Counties', 'Manage Syndicates', 'Feedback', 'Message System',
                                   'Search Statistics', 'Search Performance', 'Site Statistics', 'County Coordinators', 'Country Coordinators',
                                   'Syndicate Coordinators', 'Profile', 'RefineryCMS', 'Roadmap', 'Gazetteer', 'System Documentation',
                                   'FreeCEN Handbook', 'FreeUKGenealogy  Policies'],

      'executive_director' => ['Upload Report','GAP Report','Access Attic', 'CSV Batches', 'Communicate', 'Contacts', 'County Coordinators', 'Country Coordinators', 'Database Statistics', 'Feedback', 'FreeCen Errors', 'Gazetteer',
                               'Manage Counties', 'Manage FreeCen Coverage', 'Manage Syndicates', 'Manage Userids', 'Message System', 'Profile', 'RefineryCMS', 'Roadmap', 'Search Statistics', 'Search Performance', 'Site Statistics',
                               'Software Version Information', 'Syndicate Coordinators', 'System Documentation', 'TNA Change Logs', 'FreeCEN Handbook', 'FreeUKGenealogy  Policies'],
      'genealogy_coordinator' => ['CSV Batches', 'Communicate', 'Contacts', 'Profile', 'Roadmap', 'Gazetteer', 'System Documentation', 'FreeCEN Handbook', 'Display County Coordinators', 'Display Syndicate Coordinators',  'FreeUKGenealogy  Policies'],
      'general_communication_coordinator' => ['CSV Batches', 'Communicate', 'Display Userids', 'Feedback', 'Gazetteer', 'Message System', 'Profile', 'RefineryCMS', 'Roadmap', 'System Documentation', 'FreeUKGenealogy  Policies'],
      'project_manager' => ['Access Attic', 'CSV Batches', 'Communicate', 'Contacts', 'County Coordinators', 'Country Coordinators', 'Database Statistics', 'Feedback', 'FreeCen Errors', 'Gazetteer',
                            'Manage Counties', 'Manage FreeCen Coverage', 'Manage Syndicates', 'Manage Userids', 'Message System', 'Profile', 'RefineryCMS', 'Roadmap','Search Statistics', 'Search Performance', 'Site Statistics',
                            'Software Version Information', 'Syndicate Coordinators', 'System Documentation', 'TNA Change Logs', 'FreeCEN Handbook', 'FreeUKGenealogy  Policies'],
      'publicity_coordinator' => ['CSV Batches', 'Communicate', 'Contacts', 'Profile', 'Roadmap', 'Gazetteer', 'System Documentation', 'FreeCEN Handbook', 'Display County Coordinators', 'Display Syndicate Coordinators', 'FreeUKGenealogy  Policies'],
      'syndicate_coordinator' => ['CSV Batches', 'Gazetteer', 'FreeCEN Handbook', 'Manage Syndicate', 'Contacts', 'Communicate', 'Display Userids', 'Profile',  'Roadmap', 'FreeUKGenealogy  Policies', 'Display County Coordinators', 'Display Syndicate Coordinators'],
      'system_administrator' => ['Upload Report', 'Find Pieces','Access Attic', 'CSV Batches', 'Communicate', 'Contacts', 'Display Communications Coordinators', 'County Coordinators', 'Country Coordinators', 'Database Statistics', 'Gazetteer CSV Download', 'Feedback', 'FreeCen Errors', 'Gazetteer',
                                 'Manage Counties', 'Manage FreeCen Coverage', 'Manage Syndicates', 'Manage Userids', 'Message System', 'Place Edit Reasons', 'Place Sources', 'Physical Files', 'Profile', 'RefineryCMS', 'Roadmap', 'Search Statistics', 'Search Performance', 'Site Statistics',
                                 'Software Version Information', 'Syndicate Coordinators', 'System Documentation', 'TNA Change Logs', 'System Roles','FreeCEN Handbook', 'FreeUKGenealogy  Policies'],
      'trainee' => ['CSV Batches', 'Communicate', 'Profile', 'Roadmap', 'Gazetteer', 'FreeCEN Handbook','Display County Coordinators', 'Display Syndicate Coordinators', 'FreeUKGenealogy  Policies'],
      'technical' => ['Access Attic', 'CSV Batches', 'Communicate', 'Contacts', 'Database Statistics', 'Feedback', 'FreeCen Errors', 'Gazetteer', 'Profile', 'RefineryCMS', 'Roadmap','Search Statistics', 'Search Performance', 'Site Statistics',
                      'System Documentation', 'FreeCEN Handbook','Display County Coordinators', 'Display Syndicate Coordinators',  'FreeUKGenealogy  Policies'],

      'transcriber' => ['CSV Batches', 'Gazetteer', 'FreeCEN Handbook', 'Communicate', 'Profile', 'Roadmap', 'Display County Coordinators', 'Display Syndicate Coordinators',  'FreeUKGenealogy  Policies'],
      'transcriber_special_powers' => ['CSV Batches', 'Gazetteer', 'FreeCEN Handbook', 'Communicate', 'Contacts', 'Profile', 'Roadmap', 'Display County Coordinators', 'Display Syndicate Coordinators',  'FreeUKGenealogy  Policies'],
      'validator' => ['CSV Batches', 'Gazetteer', 'Gazetteer CSV Download', 'FreeCEN Handbook', 'Communicate', 'Profile', 'Roadmap', 'Display County Coordinators', 'Display Syndicate Coordinators', 'FreeUKGenealogy  Policies'],
      'volunteer_coordinator' => ['CSV Batches', 'Communicate', 'Contacts', 'Gazetteer', 'Manage Syndicates', 'Manage Userids', 'Profile', 'Roadmap', 'FreeCEN Handbook', 'Display County Coordinators', 'Display Syndicate Coordinators', 'FreeUKGenealogy  Policies'],
      'website_coordinator' => ['CSV Batches', 'Communicate', 'Contacts', 'Database Statistics', 'Display Userids', 'Feedback', 'Gazetteer', 'Message System','Place Edit Reasons', 'Profile', 'RefineryCMS', 'Roadmap', 'System Documentation', 'FreeCEN Handbook', 'Display County Coordinators', 'Display Syndicate Coordinators',  'FreeUKGenealogy  Policies'],
      'newsletter_coordinator' => ['Profile', 'Contacts', 'Database Statistics','Search Statistics', 'Search Performance', 'Site Statistics', 'Transcriber Statistics','Display County Coordinators', 'Display Syndicate Coordinators',  'FreeUKGenealogy  Policies'],
      'pieces_coordinator' => ['Profile', 'Find Pieces', 'CAP Report', 'FreeUKGenealogy  Policies'],
      'reporter_transcriber' => ['CSV Batches', 'Find Pieces', 'Gazetteer', 'FreeCEN Handbook', 'Communicate', 'Profile', 'Roadmap', 'Display County Coordinators', 'Display Syndicate Coordinators', 'FreeUKGenealogy  Policies', 'Manage Counties', 'GAP Report']
    }
  end
  #'/messages/communications?source=original',
  OPTIONS_TRANSLATION = {
    'Communicate' => '/messages/communications?source=original',
    'Denominations' => '/denominations',
    'Database Statistics' => '/freecen2_site_statistics/grand_totals',
    'GAP Report' => '/freecen2_pieces/gap_report',
    'GAP Reasons' => '/gap_reasons',
    'Saved Searches' => '/my_saved_searches',
    'Profile' => '/userid_details/my_own',
    'Batches' => '/freereg1_csv_files/my_own',
    'Manage Syndicate' => '/manage_syndicates',
    'Manage Syndicates' => '/manage_syndicates',
    'Manage County' => '/manage_counties',
    'Manage Counties' => '/manage_counties',
    'Manage Image Server' => '/sources/access_image_server',
    'Manage Userids' => '/userid_details/options',
    'Display Userids' => '/userid_details/display',
    'Display Syndicate Coordinators' => '/syndicates/display',
    'Display County Coordinators' => '/counties/display',
    'Display Communications Coordinators' => '/userid_details/list_users_handle_communications',
    'Syndicate Coordinators' => '/syndicates',
    'County Coordinators' => '/counties',
    'Country Coordinators' => '/countries',
    'Upload New Batch' => '/csvfiles/new',
    'RefineryCMS' => '/manage_resources/pages',
    'Access Attic' => '/attic_files/select_userid',
    'Physical Files' => '/physical_files/select_action',
    'Search Statistics' => '/freecen2_search_statistics',
    'Site Statistics' => '/site_statistics',
    'Search Performance' => '/search_queries/report',
    'Software Version Information' => '/software_versions/select_app_and_server',
    'Feedback' => '/feedbacks',
    'Contacts' => '/contacts',
    'System Documentation' => '/cms/system-documents',
    'Roadmap' => roadmap_url,
    'Logout' => '/refinery/logout',
    'Message System' => '/messages',
    'Manage Images' => '/sources',
    'Assignments' => '/assignments/my_own',
    'CSV Batches' => '/freecen_csv_files/my_own',
    'Manage Pieces' => '/freecen_pieces',
    'FreeCen Errors' => '/freecen_errors',
    'Manage FreeCen Coverage' => '/freecen_coverage/edit',
    'FreeUKGenealogy  Policies' => '/cms/freeukgenealogy-policies',
    'Gazetteer' => '/freecen2_places/search_names',
    'Gazetteer CSV Download' => '/freecen2_places/download_csv',
    'TNA Change Logs' => '/tna_change_logs',
    'Transcriber Statistics' => '/userid_details/transcriber_statistics',
    'FreeCEN Handbook' => '/cms/freecen-handbook',
    'Place Edit Reasons' => '/place_edit_reasons',
    'Upload Report' => '/physical_files/upload_report',
    'Place Sources' => '/freecen2_place_sources',
    'Find Pieces' => '/freecen2_pieces/enter_piece_number',
    'CAP Report' => '/freecen2_pieces/cap_report',
    'System Roles' => '/userid_details/list_roles_and_assignees',
    'Image Server' => '/image_server_groups',
    'Coordinators list' => '/userid_details/coordinators_list'
  }

  OPTIONS_TITLES = {
    'Communicate' => 'Communicate to a member of FreeUKGeneology',
    'Denominations' => 'Make changes to the list of denominations',
    'Database Statistics' => 'Access the FreeCEN2 database summary',
    'GAP Reasons' => 'Make changes to the list of GAP reasons',
    'Saved Searches' => 'Access your saved searches',
    'Profile' => 'Display or Edit four personal information',
    'Batches' => 'List your own FreeREG batches',
    'Manage Syndicate' => 'Manage a syndicate',
    'Manage Syndicates' => 'Manage syndicates',
    'Manage County' => 'Manage a county',
    'Manage Counties' => 'Manage a county',
    'Manage Image Server' => 'Manage the Image Server',
    'Manage Userids' => 'Manage the users',
    'Display Userids' => 'Display a list of users',
    'Display Syndicate Coordinators' => 'Display a list of syndicate coordinators',
    'Display County Coordinators' => 'Display a list of county coordinators',
    'Syndicate Coordinators' => 'Make changes to syndicates and their coordinators',
    'County Coordinators' => 'Make changes to counties and county coordinators',
    'Country Coordinators' => 'Make changes to country coordinators',
    'Upload New Batch' => 'Upload a new file',
    'RefineryCMS' => 'Manage the Refinery CMS pages',
    'Access Attic' => 'Access the attic files for a specific userid',
    'Physical Files' => 'Access information about the physical files',
    'Site Statistics' => 'Access information on the number of files and searches',
    'Search Performance' => 'Access information on the performance of the search engine',
    'Software Version Information' => 'Access information on the software updates placed on the systems',
    'Feedback' => 'Access the feedback information from members',
    'Contacts' => 'Access the contacts submitted by researchers',
    'System Documentation' => 'Access system documentation',
    'Roadmap' => 'Review the future roadmap for the application',
    'Logout' => 'Log out of the system',
    'Message System' => 'Access the message system used to send information to members',
    'Manage Images' => 'Manage the images on the image server',
    'Assignments' => 'List your assignments',
    'CSV Batches' => 'List your FreeCEN csv files',
    'Manage Pieces' => 'Access the FreeCEN1 pieces information',
    'FreeCen Errors' => 'Access the errors arising from the FreeCEN1 monthly update',
    'Manage FreeCen Coverage' => 'Access the FreeCEN1 database coverage',
    'FreeUKGenealogy  Policies' => 'Access the FreeUKGenealogy  Policies',
    'Gazetteer' => 'Search for an existing place name; opens in a new tab',
    'Gazetteer CSV Download' => 'Download CSV file of Gazetteer places for a specified County',
    'Place Edit Reasons' => 'Edit the reasons for Editing a FreeCEN2 Place',
    'Place Sources' => 'Edit sources for a FreeCEN2 Place'
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
  FILE_OPTIONS_TRANSLATION = {
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
                                 'Upload New Batch', 'Offline Reports', 'Clean Places UCF list', 'Manage Images']
  when 'freecen'
    COUNTY_MANAGEMENT_OPTIONS = ['Manage FreeCEN2 Places', 'Manage FreeCEN2 Districts', 'Manage FreeCEN2 Pieces', 'Manage FreeCEN2 Civil Parishes',
                                 'Locate Pieces', 'CAP Report','Review Batches by Filename', 'Review Batches with Errors', 'Review Batches being Validated',
                                 'Review Incorporated Batches', 'Review Specific Batch', 'Upload New Batch', 'County Statistics',
                                 'Manage FreeCEN1 Pieces', 'Manage VLD Files', 'Manage FreeCEN1 Places', 'Manage POB Propagations']
  when 'freebmd'
  end
  COUNTY_OPTIONS_TRANSLATION = {
    'All Places' => '/manage_counties/selection?option=Work with All Places',
    'Active Places' => '/manage_counties/selection?option=Work with Active Places',
    'Specific Place' => '/manage_counties/selection?option=Work with Specific Place',
    'Places with Unapproved Names' => '/manage_counties/selection?option=Places with Unapproved Names',
    'Review Batches with Errors' => '/manage_counties/selection?option=Review Batches with Errors',
    'Review Batches with Zero Dates' => '/manage_counties/selection?option=Review Batches with Zero Dates',
    'Review Batches being Validated' => '/manage_counties/selection?option=Being Validated',
    'Review Incorporated Batches' => '/manage_counties/selection?option=Incorporated',
    'Review Batches by Filename' => '/manage_counties/selection?option=Review Batches by Filename',
    'Review Batches by Userid then Filename' => '/manage_counties/selection?option=Review Batches by Userid then Filename',
    'Review Batches by Most Recent Date of Change' => '/manage_counties/selection?option=Review Batches by Most Recent Date of Change',
    'Review Batches by Oldest Date of Change' => '/manage_counties/selection?option=Review Batches by Oldest Date of Change',
    'Review Specific Batch' => '/manage_counties/selection?option=Review Specific Batch',
    'Upload New Batch' => '/csvfiles/new',
    'Manage Images' => '/manage_counties/selection?option=Manage Images',
    'Manage FreeCEN1 Pieces' => '/freecen_pieces',
    'Manage FreeCEN2 Pieces' => '/freecen2_pieces',
    'Manage FreeCEN2 Places' => '/freecen2_places',
    'Manage FreeCEN2 Districts' => '/freecen2_districts',
    'Manage FreeCEN2 Civil Parishes' => '/freecen2_civil_parishes',
    'County Statistics' => '/site_statistics',
    'Manage VLD Files' => '/freecen1_vld_files',
    'Manage FreeCEN1 Places' => '/places',
    'Offline Reports' => '/manage_counties/selection?option=Offline Reports',
    'Locate Pieces' => '/freecen2_pieces/enter_number',
    'CAP Report' => '/freecen2_pieces/cap_report',
    'Clean Places UCF list' => '/manage_counties/clean_ucf_list_for_all_places',
    'Manage POB Propagations' => '/freecen_pob_propagations'
  }
  COUNTY_OPTIONS_TITLES = {
    'All Places' => 'Lists all possible places in the county',
    'Active Places' => 'Lists only those places that have information on churches and registers',
    'Specific Place' => 'List of all places in the county from which you can select just one and review its information',
    'Places with Unapproved Names' => 'List of those places in the county where its information has not been approved',
    'Review Batches with Errors' => 'Lists just those batches that contain 1 or more errors',
    'Review Batches with Zero Dates' => 'Lists just those batches that contain have a zero in the date range',
    'Review Batches by Filename' => 'Lists all batches sorted by file name',
    'Review Batches by Userid then Filename' => 'Lists all batches sorted by userid and then file name for each userid',
    'Review Batches by Most Recent Date of Change' => 'Lists all batches sorted by the NEWEST date of change',
    'Review Batches by Oldest Date of Change' => 'Lists all batches sorted by the OLDEST date of change',
    'Review Specific Batch' => 'Lists file name/userid from which you can select just one and review its information',
    'Upload New Batch' => 'Upload a brand new file',
    'Manage Images' => 'Go to the set of actions to manage the images for the county',
    'Manage FreeCEN1 Pieces' => 'Lists all of the Pieces used by CEN1',
    'Manage FreeCEN2 Pieces' => 'Lists all of the Sub Districts (Pieces) used by CEN2. Note it may take a minute or more to prepare the list',
    'Manage FreeCEN2 Places' => 'Lists all of the official Places used by CEN2',
    'Manage FreeCEN2 Districts' => 'Lists all of the Districts used by CEN2. Note it may take a minute or more to prepare the list',
    'Manage FreeCEN2 Civil Parishes' => 'Lists all of the Civil Parishes used by CEN2. Note it may take a minute or more to prepare the list',
    'County Statistics' => 'Access to the statistics for the county',
    'Manage VLD Files' => 'Minimal tools to manage VLD files',
    'Manage Places' => 'Minimal tools to manage places used by CEN1',
    'Offline Reports' => 'Generate off line reports',
    'Locate Pieces' => 'Locates Pieces in other counties, perhaps as a result of a move',
    'Manage POB Propagations' => 'Manage POB Propagations'
  }
  case MyopicVicar::Application.config.template_set
  when 'freereg'
    SYNDICATE_MANAGEMENT_OPTIONS = ['Review Active Members', 'Review All Members', 'Transcription Agreement Accepted',
                                    'Transcription Agreement Not Accepted', 'Select Specific Member by Userid',
                                    'Select Specific Member by Email Address', 'Select Specific Member by Surname/Forename',
                                    'Incomplete Registrations', 'Syndicate Messages', 'Review Batches with Errors',
                                    'Review Batches with Zero Dates', 'Review Batches by Filename', 'Review Batches by Userid then Filename',
                                    'Review Batches by Most Recent Date of Change', 'Review Batches by Oldest Date of Change',
                                    'Review Specific Batch', 'List files waiting to be processed', 'List files NOT processed', 'Upload New Batch',
                                    'Change Recruiting Status', 'Manage Images']
  when 'freecen'
    SYNDICATE_MANAGEMENT_OPTIONS = ['Review Active Members', 'Review All Members', 'Transcription Agreement Accepted',
                                    'Transcription Agreement Not Accepted', 'Select Specific Member by Userid',
                                    'Select Specific Member by Email Address', 'Select Specific Member by Surname/Forename',
                                    'Incomplete Registrations', 'Syndicate Messages', 'Change Recruiting Status']
  when 'freebmd'
  end

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

  def roadmap_url
    url = Rails.application.config.template_set == 'freecen' ? 'https://docs.google.com/document/d/1tOX_6_fyslNIf-ArsChKnhv7XSgpKjAuBD3RwdoaGlg/edit?usp=sharing' : '/cms/system-documents/development-roadmap'
    url
  end
end
