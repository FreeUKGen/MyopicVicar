# Copyright 2012 Trustees of FreeBMD
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
MyopicVicar::Application.routes.draw do

  root :to => 'search_queries#new'

  # Mikes winfreereg request

  get 'transreg_csvfiles/delete'
  post 'transreg_csvfiles/upload'
  post 'transreg_csvfiles/replace'

  get 'transreg_batches/list'
  get 'transreg_batches/download'
  get 'transreg_churches/list'
  get 'transreg_places/list'
  get 'transreg_counties/register_types'
  get 'transreg_counties/all_register_types'
  get 'transreg_counties/list'
  get 'transreg_users/refreshuser'
  get 'transreg_users/authenticate'
  get 'transreg_users/computer'
  resources :transreg_counties
  resources :transreg_users

  # end mikes request



  get 'software_versions/:id/commitments(.:format)',  :to => 'software_versions#commitments', :as => :commitments_software_versions
  resources :software_versions


  resources :denominations


  delete 'messages/:id/remove_from_userid_detail(.:format)', :to => 'messages#remove_from_userid_detail', :as => :remove_from_userid_detail
  get 'messages/userid_messages', :to => 'messages#userid_messages', :as => :userid_messages
  get 'messages/list_by_type',  :to => 'messages#list_by_type', :as => :list_by_type_messages
  get 'messages/:id/send_message(.:format)',  :to => 'messages#send_message', :as => :send_message_messages
  get 'messages/list_by_name',  :to => 'messages#list_by_name', :as => :list_by_name_messages
  get 'messages/list_by_date',  :to => 'messages#list_by_date', :as => :list_by_date_messages
  get 'messages/list_by_most_recent',  :to => 'messages#list_by_most_recent', :as => :list_by_most_recent_messages
  get 'messages/list_feedback_reply_messages',  :to => 'messages#list_feedback_reply_message', :as => :list_feedback_reply_message
  get 'messages/list_contact_reply_messages',  :to => 'messages#list_contact_reply_message', :as => :list_contact_reply_message
  get 'messages/select_by_identifier',  :to => 'messages#select_by_identifier', :as => :select_by_identifier_messages
  get 'messages/:id/reply',  :to => 'messages#new', :as => :reply_messages
  get 'messages/:id/show_reply_messages',:to => 'messages#show_reply_messages', :as => :show_reply_messages
  get 'messages/:id/user_reply_messages',:to => 'messages#user_reply_messages', :as => :user_reply_messages
  get 'messages/userid_reply_messages', :to => 'messages#userid_reply_messages', :as => :userid_reply_messages
  get 'messages/list_unsent_messages',  :to => 'messages#list_unsent_messages', :as => :list_unsent_messages
  get 'messages/list_syndicate_messages',  :to => 'messages#list_syndicate_messages', :as => :list_syndicate_messages
  get 'messages/list_archived_syndicate_messages',  :to => 'messages#list_archived_syndicate_messages', :as => :list_archived_syndicate_messages
  get 'messages/:id/archive',  :to => 'messages#archive', :as => :archive_message
  get 'messages/:id/restore',  :to => 'messages#restore', :as => :restore_message
  get 'messages/:id/force_destroy',  :to => 'messages#force_destroy', :as => :force_destroy_messages

  resources :messages

  get 'attic_files/select', :to =>'attic_files#select', :as => :select_attic_files
  get 'attic_files/select_userid', :to =>'attic_files#select_userid', :as => :select_userid_attic_files
  get 'attic_files/:id/download(.:format)', :to => 'attic_files#download', :as => :download_attic_file
  resources :attic_files

  get 'physical_files/files_for_specific_userid', :to =>'physical_files#files_for_specific_userid', :as => :files_for_specific_userid_physical_files
  get 'physical_files/processed_but_no_file', :to =>'physical_files#processed_but_no_file', :as => :processed_but_no_file_physical_files
  get 'physical_files/file_not_processed', :to =>'physical_files#file_not_processed', :as => :file_not_processed_physical_files
  get 'physical_files/select_action',  :to => 'physical_files#select_action', :as => :select_action_physical_files
  get 'physical_files/:id/submit_for_processing(.:format)',  :to => 'physical_files#submit_for_processing', :as => :submit_for_processing_physical_file
  get 'physical_files/:id/reprocess(.:format)',  :to => 'physical_files#reprocess', :as => :reprocess_physical_file
  get 'physical_files/all_files', :to => 'physical_files#all_files', :as => :all_files_physical_files
  get 'physical_files/waiting_to_be_processed', :to => 'physical_files#waiting_to_be_processed', :as => :waiting_to_be_processed_physical_files
  get 'physical_files/:id/download(.:format)', :to => 'physical_files#download', :as => :download_physical_file
  get 'physical_files/:id/remove(.:format)', :to => 'physical_files#remove', :as => :remove_physical_file
  resources :physical_files

  resources :search_statistics

  resources :site_statistics

  get 'feedbacks/list_by_userid',  :to => 'feedbacks#list_by_userid', :as => :list_by_userid_feedbacks
  get 'feedbacks/list_by_name',  :to => 'feedbacks#list_by_name', :as => :list_by_name_feedbacks
  get 'feedbacks/list_by_date',  :to => 'feedbacks#list_by_date', :as => :list_by_date_feedbacks
  get 'feedbacks/list_by_most_recent',  :to => 'feedbacks#list_by_most_recent', :as => :list_by_most_recent_feedbacks
  get 'feedbacks/list_by_identifier',  :to => 'feedbacks#list_by_identifier', :as => :list_by_identifier_feedbacks
  get 'feedbacks/list_archived',  :to => 'feedbacks#list_archived', :as => :list_archived_feedbacks
  get 'feedbacks/select_by_identifier',  :to => 'feedbacks#select_by_identifier', :as => :select_by_identifier_feedbacks
  post 'feedbacks/:id/convert_to_issue(.:format)', :to => 'feedbacks#convert_to_issue', :as => :convert_feedback_to_issue
  get 'feedbacks/userid_feedbacks', :to => 'feedbacks#userid_feedbacks', :as => :userid_feedbacks
  get 'feedbacks/userid_feedbacks_with_replies', :to => 'feedbacks#userid_feedbacks_with_replies', :as => :userid_feedbacks_with_replies
  get 'feedbacks/:id/force_destroy',  :to => 'feedbacks#force_destroy', :as => :force_destroy_feedback
  get 'feedbacks/:id/archive',  :to => 'feedbacks#archive', :as => :archive_feedback
  get 'feedbacks/:id/restore',  :to => 'feedbacks#restore', :as => :restore_feedback
  get 'feedbacks/:source_feedback_id/reply',  :to => 'feedbacks#reply_feedback', :as => :reply_feedback
  get 'feedbacks/:id/feedback_reply_messages', to: 'feedbacks#feedback_reply_messages', as: :feedback_reply_messages
  resources :feedbacks



  get 'contacts/list_by_type',  :to => 'contacts#list_by_type', :as => :list_by_type_contacts
  get 'contacts/list_by_name',  :to => 'contacts#list_by_name', :as => :list_by_name_contacts
  get 'contacts/list_by_date',  :to => 'contacts#list_by_date', :as => :list_by_date_contacts
  get 'contacts/list_by_most_recent',  :to => 'contacts#list_by_most_recent', :as => :list_by_most_recent_contacts
  get 'contacts/list_by_identifier',  :to => 'contacts#list_by_identifier', :as => :list_by_identifier_contacts
  get 'contacts/list_archived',  :to => 'contacts#list_archived', :as => :list_archived_contacts
  get 'contacts/select_by_identifier',  :to => 'contacts#select_by_identifier', :as => :select_by_identifier_contacts
  get  'contacts/:id(.:format)/report_error', :to => 'contacts#report_error', :as => :report_error_contact
  get 'contacts/:source_contact_id/reply',  :to => 'contacts#reply_contact', :as => :reply_contact
  get 'contacts/:id/contact_reply_messages', to: 'contacts#contact_reply_messages', as: :contact_reply_messages
  get 'contacts/:id/force_destroy',  :to => 'contacts#force_destroy', :as => :force_destroy_contact
  get 'contacts/:id/archive',  :to => 'contacts#archive', :as => :archive_contact
  get 'contacts/:id/restore',  :to => 'contacts#restore', :as => :restore_contact
  post 'contacts/:id/convert_to_issue(.:format)', :to => 'contacts#convert_to_issue', :as => :convert_contact_to_issue

  resources :contacts

  resources :place_caches


  get  'manage_syndicates/selection',  :to => 'manage_syndicates#review_all_members', constraints: ManageSyndicatesAllMembersConstraint
  get  'manage_syndicates/selection',  :to => 'manage_syndicates#review_active_members', constraints: ManageSyndicatesActiveMembersConstraint
  get  'manage_syndicates/selection',  :to => 'manage_syndicates#member_by_email', constraints: ManageSyndicatesMemberByEmailConstraint
  get  'manage_syndicates/selection',  :to => 'manage_syndicates#member_by_userid', constraints: ManageSyndicatesMemberByUseridConstraint
  get  'manage_syndicates/selection',  :to => 'manage_syndicates#member_by_name', constraints: ManageSyndicatesMemberByNameConstraint
  get  'manage_syndicates/selection',  :to => 'manage_syndicates#batches_with_errors', constraints: ManageCountiesErrorBatchConstraint
  get  'manage_syndicates/selection',  :to => 'manage_syndicates#display_by_filename', constraints: ManageCountiesDisplayByFilenameConstraint
  get  'manage_syndicates/selection',  :to => 'manage_syndicates#upload_batch', constraints: ManageCountiesUploadBatchConstraint
  get  'manage_syndicates/selection',  :to => 'manage_syndicates#display_by_userid_filename', constraints: ManageCountiesUseridFilenameConstraint
  get  'manage_syndicates/selection',  :to => 'manage_syndicates#display_by_descending_uploaded_date', constraints: ManageCountiesDescendingConstraint
  get  'manage_syndicates/selection',  :to => 'manage_syndicates#display_by_ascending_uploaded_date', constraints: ManageCountiesAscendingConstraint
  get  'manage_syndicates/selection',  :to => 'manage_syndicates#review_a_specific_batch', constraints: ManageCountiesReviewBatchConstraint
  get  'manage_syndicates/selection',  :to => 'manage_syndicates#change_recruiting_status', constraints: ManageSyndicatesChangeRecruitingStatusConstraint
  get  'manage_syndicates/selection',  :to => 'manage_syndicates#manage_image_group', constraints: ManageSyndicatesManageImagesConstraint
  get  'manage_syndicates/select_action',  :to => 'manage_syndicates#select_action', :as => :select_action_manage_syndicates
  get  'manage_syndicates/display_files_not_processed',  :to => 'manage_syndicates#display_files_not_processed', :as => :display_files_not_processed_manage_syndicates
  get  'manage_syndicates/:id/selected(.:format)',  :to => 'manage_syndicates#selected', :as => :selected_manage_syndicates
  get  'manage_syndicates/display_files_waiting_to_be_processed',  :to => 'manage_syndicates#display_files_waiting_to_be_processed', :as => :display_files_waiting_to_be_processed_manage_syndicates
  get 'manage_syndicates/manage_image_group', :to => 'manage_syndicates#manage_image_group', :as => :manage_image_group_manage_syndicate
  get 'manage_syndicates/:id/list_fully_reviewed_group', :to => 'manage_syndicates#list_fully_reviewed_group', :as => :list_fully_reviewed_group_manage_syndicate
  get 'manage_syndicatess/:id/list_fully_transcribed_group', :to => 'manage_syndicates#list_fully_transcribed_group', :as => :list_fully_transcribed_group_manage_syndicate
  resources :manage_syndicates

  resources :csvfiles
  get 'csvfiles/:id/error(.:format)', :to => 'csvfiles#replace', :as => :replace_csvfile
  get 'csvfiles/:id/download(.:format)', :to => 'csvfiles#download', :as => :download_csvfile

  resources :countries

  get 'counties/display', :to =>'counties#display', :as => :display_counties
  get 'counties/select', :to =>'counties#select', :as => :select_counties
  get 'counties/selection', :to =>'counties#selection', :as => :selection_counties
  resources :counties


  resources :my_saved_searches


  get 'manage_resources/pages', :to =>'manage_resources#pages', :as => :pages_manage_resources
  get 'manage_resources/logout', :to =>'manage_resources#logout', :as => :logout_manage_resources
  get 'manage_resources/selection', :to =>'manage_resources#selection', :as => :selection_manage_resources
  resources :manage_resources


  get 'userid_details/confirm_email_address', :to =>'userid_details#confirm_email_address', :as => :confirm_email_address_userid_details
  get 'userid_details/role', :to =>'userid_details#role', :as => :role_userid_detail
  get 'userid_details/secondary', :to =>'userid_details#secondary', :as => :secondary_userid_detail
  get 'userid_details/person_roles', :to =>'userid_details#person_roles', :as => :person_roles_userid_detail
  get 'userid_details/secondary_roles', :to =>'userid_details#secondary_roles', :as => :secondary_roles_userid_detail
  get 'userid_details/:id/change_password', :to =>'userid_details#change_password', :as => :change_password_userid_detail
  get 'userid_details/researcher_registration', :to =>'userid_details#researcher_registration', :as => :researcher_registration_userid_detail
  get 'userid_details/transcriber_registration', :to =>'userid_details#transcriber_registration', :as => :transcriber_registration_userid_detail
  get 'userid_details/technical_registration', :to =>'userid_details#technical_registration', :as => :technical_registration_userid_detail
  get 'userid_details/general', :to =>'userid_details#general', :as => :general_userid_detail
  get 'userid_details/:id/disable(.:format)', :to => 'userid_details#disable', :as => :disable_userid_detail
  get 'userid_details/:id/syndicate(.:format)', :to => 'userid_details#syndicate', :as => :syndicate_userid_detail
  get 'userid_details/my_own',  :to => 'userid_details#my_own', :as => :my_own_userid_detail
  get 'userid_details/all', :to => 'userid_details#all', :as => :all_userid_detail
  get 'userid_details/select', :to =>'userid_details#select', :as => :select_userid_details
  get 'userid_details/selection', :to =>'userid_details#selection', :as => :selection_userid_details
  get 'userid_details/options', :to =>'userid_details#options', :as => :options_userid_details
  get 'userid_details/display', :to =>'userid_details#display', :as => :display_userid_details
  get 'userid_details/incomplete_registrations', :to =>'userid_details#incomplete_registrations', :as => :incomplete_registrations_userid_details
  get 'userid_details/transcriber_statistics', :to =>'userid_details#transcriber_statistics', :as => :transcriber_statistics_userid_details
  post 'userid_details/new', :to => 'userid_details#create'
  resources :userid_details


  get  'manage_counties/selection',  :to => 'manage_counties#work_all_places', constraints: ManageCountiesAllPlacesConstraint ,:as => :selection_all_manage_counties
  get  'manage_counties/selection',  :to => 'manage_counties#work_with_active_places', constraints: ManageCountiesActivePlacesConstraint ,:as => :selection_active_manage_counties
  get  'manage_counties/selection',  :to => 'manage_counties#work_with_specific_place', constraints: ManageCountiesSpecificPlaceConstraint
  get  'manage_counties/selection',  :to => 'manage_counties#places_with_unapproved_names', constraints: ManageCountiesUnapprovedNamesConstraint
  get  'manage_counties/selection',  :to => 'manage_counties#batches_with_errors', constraints: ManageCountiesErrorBatchConstraint
  get  'manage_counties/selection',  :to => 'manage_counties#display_by_filename', constraints: ManageCountiesDisplayByFilenameConstraint
  get  'manage_counties/selection',  :to => 'manage_counties#upload_batch', constraints: ManageCountiesUploadBatchConstraint
  get  'manage_counties/selection',  :to => 'manage_counties#upload_batch', constraints: ManageCountiesUploadBatchConstraint
  get  'manage_counties/selection',  :to => 'manage_counties#display_by_userid_filename', constraints: ManageCountiesUseridFilenameConstraint
  get  'manage_counties/selection',  :to => 'manage_counties#display_by_descending_uploaded_date', constraints: ManageCountiesDescendingConstraint
  get  'manage_counties/selection',  :to => 'manage_counties#display_by_ascending_uploaded_date', constraints: ManageCountiesAscendingConstraint
  get  'manage_counties/selection',  :to => 'manage_counties#review_a_specific_batch', constraints: ManageCountiesReviewBatchConstraint
  get  'manage_counties/selection',  :to => 'manage_counties#manage_sources', constraints:ManageCountiesManageImagesConstraint
  get  'manage_counties/manage_image_group(.:format)', :to => 'manage_counties#manage_image_group', :as => :manage_image_group_manage_county
  get  'manage_counties/manage_unallocated_image_group(.:format)', :to => 'manage_counties#manage_unallocated_image_group', :as => :manage_unallocated_image_group_manage_county
  get  'manage_counties/manage_allocate_request_image_group(.:format)', :to => 'manage_counties#manage_allocate_request_image_group', :as => :manage_allocate_request_image_group_manage_county
  get  'manage_counties/manage_completion_submitted_image_group(.:format)', :to => 'manage_counties#manage_completion_submitted_image_group', :as => :manage_completion_submitted_image_group_manage_county
  get  'manage_counties/sort_image_group_by_syndicate(.:format)', :to => 'manage_counties#sort_image_group_by_syndicate', :as => :sort_image_group_by_syndicate
  get  'manage_counties/sort_image_group_by_place(.:format)', :to => 'manage_counties#sort_image_group_by_place', :as => :sort_image_group_by_place
  get 'manage_counties/uninitialized_source_list(.:format)', :to => 'manage_counties#uninitialized_source_list', :as => :uninitialized_source_list
  get  'manage_counties/select_file',  :to => 'manage_counties#select_file', :as => :select_file_manage_counties
  get  'manage_counties/select_action',  :to => 'manage_counties#select_action', :as => :select_action_manage_counties
  get  'manage_counties/:id/selected(.:format)',  :to => 'manage_counties#selected', :as => :selected_manage_counties
  get 'manage_counties/select', :to =>'manage_counties#select', :as => :select_manage_counties
  get 'manage_counties/files', :to =>'manage_counties#files', :as => :files_manage_counties
  get 'manage_counties/places', :to =>'manage_counties#places', :as => :places_manage_counties
  get 'manage_counties/place_range', :to =>'manage_counties#place_range', :as => :place_range_manage_counties
  resources :manage_counties


  get 'syndicates/display', :to =>'syndicates#display', :as => :display_syndicates
  get 'syndicates/select', :to =>'syndicates#select', :as => :select_syndicates
  get 'syndicates/selection', :to =>'syndicates#selection', :as => :selection_syndicates
  resources :syndicates

  resources :coordinators

  resources :alias_place_churches

  get 'freereg_contents/:id/show(.:format)', :to => 'freereg_contents#show', :as => :show_freereg_content
  get 'freereg_contents/:id/show_place(.:format)', :to => 'freereg_contents#show_place', :as => :show_place_freereg_content
  get 'freereg_contents/:id/show_church(.:format)', :to => 'freereg_contents#show_church', :as => :show_church_freereg_content
  get 'freereg_contents/:id/show_register(.:format)', :to => 'freereg_contents#show_register', :as => :show_register_freereg_content
  get 'freereg_contents/:id/place(.:format)', :to => 'freereg_contents#place', :as => :place_freereg_content
  get 'freereg_contents/:id/church(.:format)', :to => 'freereg_contents#church', :as => :church_freereg_content
  get 'freereg_contents/:id/register(.:format)', :to => 'freereg_contents#register', :as => :register_freereg_content
  get 'freereg_contents/select_places(.:format)', :to => 'freereg_contents#select_places', :as => :select_places_freereg_content
  post 'freereg_contents/send_request_email(.:format)', :to => 'freereg_contents#send_request_email', :as => :send_request_email_freereg_content
  resources :freereg_contents


  get 'churches/:id/rename', :to => 'churches#rename', :as => :rename_church
  get 'churches/:id/merge(.:format)', :to => 'churches#merge', :as => :merge_church
  get 'churches/:id/relocate(.:format)', :to => 'churches#relocate', :as => :relocate_church
  resources :churches

  get 'registers/:id/rename', :to => 'registers#rename', :as => :rename_register
  get 'registers/:id/merge(.:format)', :to => 'registers#merge', :as => :merge_register
  get 'registers/:id/relocate', :to => 'registers#relocate', :as => :relocate_register
  get 'registers/:id/create_image_server', :to => 'registers#create_image_server', :as => :create_image_server_register
  get 'registers/create_image_server_return', :to => 'registers#create_image_server_return', :as => :create_image_server_return_register
  resources :registers

  resources :master_place_names

  get 'places/:id/approve', :to => 'places#approve', :as => :approve_place
  get 'places/:id/rename', :to => 'places#rename', :as => :rename_place
  get 'places/:id/merge(.:format)', :to => 'places#merge', :as => :merge_place
  get 'places/:id/relocate(.:format)', :to => 'places#relocate', :as => :relocate_place
  get 'places/for_search_form(.:format)', :to => 'places#for_search_form', :as => :places_for_search_form
  get 'places/for_freereg_content_form(.:format)', :to => 'places#for_freereg_content_form', :as => :places_for_freereg_content_form
  resources :places

  resources :church_names

  resources :toponyms

  get 'freereg1_csv_entries/:id/error(.:format)', :to => 'freereg1_csv_entries#error', :as => :error_freereg1_csv_entry
  resources :freereg1_csv_entries

  get 'freereg1_csv_files/:id/change_userid', :to => 'freereg1_csv_files#change_userid', :as => :change_userid_freereg1_csv_file
  get 'freereg1_csv_files/update_counties', :to => 'freereg1_csv_files#update_counties', :as => :update_counties
  get 'freereg1_csv_files/update_places', :to => 'freereg1_csv_files#update_places', :as => :update_places
  get 'freereg1_csv_files/update_churches', :to => 'freereg1_csv_files#update_churches', :as => :update_churches
  get 'freereg1_csv_files/update_registers', :to => 'freereg1_csv_files#update_registers', :as => :update_registers
  get 'freereg1_csv_files/:id/merge', :to => 'freereg1_csv_files#merge', :as => :merge_freereg1_csv_file
  get 'freereg1_csv_files/:id/remove', :to => 'freereg1_csv_files#remove', :as => :remove_freereg1_csv_file
  get 'freereg1_csv_files/:id/relocate(.:format)', :to => 'freereg1_csv_files#relocate', :as => :relocate_freereg1_csv_file
  get 'freereg1_csv_files/:id/lock(.:format)', :to => 'freereg1_csv_files#lock', :as => :lock_freereg1_csv_file
  get 'freereg1_csv_files/:id/error(.:format)', :to => 'freereg1_csv_files#error', :as => :error_freereg1_csv_file
  get 'freereg1_csv_files/my_own',  :to => 'freereg1_csv_files#my_own', :as => :my_own_freereg1_csv_file
  get 'freereg1_csv_files/:id/by_userid',  :to => 'freereg1_csv_files#by_userid', :as => :by_userid_freereg1_csv_file
  get 'freereg1_csv_files/display_my_error_files',  :to => 'freereg1_csv_files#display_my_error_files', :as => :display_my_error_files
  get 'freereg1_csv_files/display_my_own_files',  :to => 'freereg1_csv_files#display_my_own_files', :as => :display_my_own_files_freereg1_csv_file
  get 'freereg1_csv_files/display_my_own_files_by_descending_uploaded_date',  :to => 'freereg1_csv_files#display_my_own_files_by_descending_uploaded_date',  :as => :display_my_own_files_by_descending_uploaded_date_freereg1_csv_file
  get 'freereg1_csv_files/display_my_own_files_by_ascending_uploaded_date',  :to => 'freereg1_csv_files#display_my_own_files_by_ascending_uploaded_date', :as => :display_my_own_files_by_ascending_uploaded_date_freereg1_csv_file
  get 'freereg1_csv_files/display_my_own_files_by_selection',  :to => 'freereg1_csv_files#display_my_own_files_by_selection', :as => :display_my_own_files_by_selection_freereg1_csv_file
  get 'freereg1_csv_files/display_my_own_files_waiting_to_be_processed',  :to => 'freereg1_csv_files#display_my_own_files_waiting_to_be_processed', :as => :display_my_own_files_waiting_to_be_processed_freereg1_csv_file
  get 'freereg1_csv_files/:id/download(.:format)', :to => 'freereg1_csv_files#download', :as => :download_freereg1_csv_file
  get 'freereg1_csv_files/unique_names', :to => 'freereg1_csv_files#unique_names', :as => :unique_names_freereg1_csv_file
  get 'freereg1_csv_files/:id/zero_year', :to => 'freereg1_csv_files#zero_year', :as => :zero_year_freereg1_csv_file
  get 'freereg1_csv_files/:id/zero_year_entries', :to => 'freereg1_csv_files#show_zero_startyear_entries', :as => :show_zero_startyear_entries_freereg1_csv_file
  resources :freereg1_csv_files

  resources :emendation_types

  resources :emendation_rules

  resources :search_names


  get 'search_records/:id/show_print_version(.:format)', :to => 'search_records#show_print_version', :as => :show_print_version_search_record
  resources :search_records

  # For generating the citations
  get 'search_records/:id/show_citation', :to => 'search_records#show_citation', :as => :show_citation_record
  resources :search_records

  get 'search_queries/:id/show_query', :to => 'search_queries#show_query', :as => :show_query_search_query
  get 'search_queries/:id/show_print_version', :to => 'search_queries#show_print_version', :as => :show_print_version_search_query
  get 'search_queries/:id/about(.:format)', :to => 'search_queries#about', :as => :about_search_query
  get 'search_queries/:id/broaden(.:format)', :to => 'search_queries#broaden', :as => :broaden_search_query
  get 'search_queries/:id/narrow(.:format)', :to => 'search_queries#narrow', :as => :narrow_search_query
  post 'search_queries/:id/remember(.:format)', :to => 'search_queries#remember', :as => :remember_search_query
  get 'search_queries/:id/reorder(.:format)', :to => 'search_queries#reorder', :as => :reorder_search_query
  get 'search_queries/report(.:format)', :to => 'search_queries#report', :as => :search_query_report
  get 'search_queries/selection',  :to => 'search_queries#selection', :as => :select_search_query_report
  post 'search_queries/:id/analyze(.:format)', :to => 'search_queries#analyze', :as => :analyze_search_query
  resources :search_queries

  resources :s3buckets

  resources :fields

  resources :templates

  resources :entities

  resources :asset_collections

  resources :assets

  get 'sources/access_image_server', :to => 'sources#access_image_server', :as => :access_image_server_source
  resources :sources
  get 'sources/:id/flush(.:format)', :to => 'sources#flush', :as => :flush_source
  get 'sources/:id/index(.:format)', :to => 'sources#index', :as => :index_source
  get 'sources/:id/propagate(.:format)', :to => 'sources#propagate', :as => :propagate_source
  get 'sources/:id/initialize_status(.:format)', :to => 'sources#initialize_status', :as => :initialize_status_source


  get 'image_server_images/download', :to => 'image_server_images#download', :as => :download_image_server_image
  get 'image_server_images/view', :to => 'image_server_images#view', :as => :view_image_server_image
  get 'image_server_images/:id/flush(.:format)', :to => 'image_server_images#flush', :as => :flush_image_server_image
  get 'image_server_images/:id/index(.:format)', :to => 'image_server_images#index', :as => :index_image_server_image
  get 'image_server_images/:id/move(.:format)', :to => 'image_server_images#move', :as => :move_image_server_image
  get 'image_server_images/return_from_image_deletion', :to => 'image_server_images#return_from_image_deletion', :as => :return_from_image_deletion_image_server_image
  resources :image_server_images

  get 'image_server_groups/my_list_by_syndicate', :to => 'image_server_groups#my_list_by_syndicate', :as => :my_list_by_syndicate_image_server_group
  get 'image_server_groups/:id/my_list_by_county(.:format)', :to => 'image_server_groups#my_list_by_county', :as => :my_list_by_county_image_server_group
  get 'image_server_groups/:id/allocate(.:format)', :to => 'image_server_groups#allocate', :as => :allocate_image_server_group
  get 'image_server_groups/:id/initialize_status(.:format)', :to => 'image_server_groups#initialize_status', :as => :initialize_status_image_server_group
  get 'image_server_groups/:id/index(.:format)', :to => 'image_server_groups#index', :as => :index_image_server_group
  get 'image_server_groups/:id/upload(.:format)', :to => 'image_server_groups#upload', :as => :upload_image_server_group
  get 'image_server_groups/upload_return', :to => 'image_server_groups#upload_return', :as => :upload_return_image_server_group
  get 'image_server_groups/:id/request_cc_image_server_group(.:format)', :to => 'image_server_groups#request_cc_image_server_group', :as => :request_cc_image_server_group
  get 'image_server_groups/:id/request_sc_image_server_group(.:format)', :to => 'image_server_groups#request_sc_image_server_group', :as => :request_sc_image_server_group
  get 'image_server_groups/:id/send_complete_to_cc(.:format)', :to => 'image_server_groups#send_complete_to_cc', :as => :send_complete_to_cc_image_server_group
  resources :image_server_groups

  get 'assignments/:id/assign(.:format)', :to => 'assignments#assign', :as => :assign_assignment
  get 'assignments/:id/re_assign(.:format)', :to => 'assignments#re_assign', :as => :re_assign_assignment
  get 'assignments/:id/select_user(.:format)', :to => 'assignments#select_user', :as => :select_user_assignment
  get 'assignments/:id/list_assignments_by_syndicate_coordinator(.:format)', :to => 'assignments#list_assignments_by_syndicate_coordinator', :as => :list_assignments_by_syndicate_coordinator_assignment
  get 'assignments/:id/list_assignments_of_myself(.:format)', :to => 'assignments#list_assignments_of_myself', :as => :list_assignments_of_myself_assignment
  get 'assignments/:id/list_assignment_image(.:format)', :to => 'assignments#list_assignment_image', :as => :list_assignment_image_assignment
  get 'assignments/:id/list_assignment_images(.:format)', :to => 'assignments#list_assignment_images', :as => :list_assignment_images_assignment
  get 'assignments/:id/list_submitted_transcribe_assignments(.:format)', :to => 'assignments#list_submitted_transcribe_assignments', :as => :list_submitted_transcribe_assignments_assignment
  get 'assignments/:id/list_submitted_review_assignments(.:format)', :to => 'assignments#list_submitted_review_assignments', :as => :list_submitted_review_assignments_assignment
  get 'assignments/my_own', :to => 'assignments#my_own', :as => :my_own_assignment
  get 'assignment/image_completed', :to => 'assignments#image_completed', :as => :user_complete_image_assignment
  get 'assignments/select_county', :to => 'assignments#select_county', :as => :select_county_assignment
  get 'assignments/:id/list_by_syndicate(.:format)', :to => 'assignments#list_by_syndicate', :as => :list_by_syndicate_assignment
  resources :assignments

  get 'gaps/:id/index(.:format)', :to => 'gaps#index', :as => :index_gap
  resources :gaps

  get 'gap_reasons/:id/index(.:format)', :to => 'gap_reasons#index', :as => :index_gap_reason
  resources :gap_reasons



  # This line mounts Refinery's routes at the root of your application.
  # This means, any requests to the root URL of your application will go to Refinery::PagesController#home.
  # If you would like to change where this extension is mounted, simply change the :at option to something different.
  #
  # We ask that you don't use the :as option here, as Refinery relies on it being the default of "refinery"

  mount Refinery::Core::Engine, :at => '/cms'

  #ActiveAdmin.routes(self)

  #devise_for :admin_users, ActiveAdmin::Devise.config



  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
