module ReplyUseridRole
  GENERAL_REPLY_ROLES = ['system_administrator', 'executive_director', 'engagement_coordinator', 'website_coordinator', 'general_communication_coordinator', 'volunteer_coordinator']
  COORDINATOR_ROLES = ['syndicate_coordinator', 'county_coordinator', 'country_coordinator', 'system_administrator', 'volunteer_coordinator', 'documentation_coordinator', 'data_manager']
  NO_REPLY_ROLES = ['researcher', 'computer', 'trainee', 'pending', 'transcriber', 'technical', 'contacts_coordinator', 'project_manager', 'publicity_coordinator', 'genealogy_coordinator',]

  #Coordinator roles should have access to only those messages that are sent to members_of_syndicate
  # other messages to coordinator roles can only view userid messages but no reply action

  #Roles that has access to MessageSystem/ Roles that can reply: 
  #'system_administrator'; 'executive_director'; 'engagement_coordinator'; 'website_coordinator'; 'general_communication_coordinator'; 'volunteer_coordinator';
  #

  #Roles that has access to Manage Syndicate
  #'syndicate_coordinator'; 'county_coordinator'; 'country_coordinator'; 'system_administrator'; 'volunteer_coordinator'; 'documentation_coordinator'; 'data_manager'
end