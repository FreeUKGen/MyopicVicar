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


  resources :freecen1_fixed_dat_files


  resources :freecen1_fixed_dat_entries


  resources :freecen_dwellings


  resources :freecen_individuals


  #resources :site_statistics


  resources :freecen1_vld_entries


  resources :freecen1_vld_files

  get 'messages/list_by_type',  :to => 'messages#list_by_type', :as => :list_by_type_messages
  get 'messages/:id/send_message(.:format)',  :to => 'messages#send_message', :as => :send_message_messages
  get 'messages/list_by_name',  :to => 'messages#list_by_name', :as => :list_by_name_messages
  get 'messages/list_by_date',  :to => 'messages#list_by_date', :as => :list_by_date_messages
  get 'messages/list_by_identifier',  :to => 'messages#list_by_identifier', :as => :list_by_identifier_messages
  get 'messages/select_by_identifier',  :to => 'messages#select_by_identifier', :as => :select_by_identifier_messages
  resources :messages

  get 'attic_files/select', :to =>'attic_files#select', :as => :select_attic_files
  get 'attic_files/select_userid', :to =>'attic_files#select_userid', :as => :select_userid_attic_files
  get 'attic_files/:id/download(.:format)', :to => 'attic_files#download', :as => :download_attic_file
  resources :attic_files

  get 'physical_files/files_for_county', :to =>'physical_files#files_for_county', :as => :files_for_county_physical_files
  get 'physical_files/files_for_specific_userid', :to =>'physical_files#files_for_specific_userid', :as => :files_for_specific_userid_physical_files
  get 'physical_files/processed_but_no_files', :to =>'physical_files#processed_but_no_files', :as => :processed_but_no_files_physical_files
  get 'physical_files/processed_but_no_file_in_fr1', :to =>'physical_files#processed_but_no_file_in_fr1', :as => :processed_but_no_file_in_fr1_physical_files
  get 'physical_files/processed_but_no_file_in_fr2', :to =>'physical_files#processed_but_no_file_in_fr2', :as => :processed_but_no_file_in_fr2_physical_files
  get 'physical_files/file_not_processed', :to =>'physical_files#file_not_processed', :as => :file_not_processed_physical_files
  get 'physical_files/select_action',  :to => 'physical_files#select_action', :as => :select_action_physical_files
  get 'physical_files/:id/submit_for_processing(.:format)',  :to => 'physical_files#submit_for_processing', :as => :submit_for_processing_physical_file
  get 'physical_files/:id/reprocess(.:format)',  :to => 'physical_files#reprocess', :as => :reprocess_physical_file
  get 'physical_files/all_files', :to => 'physical_files#all_files', :as => :all_files_physical_files
  get 'physical_files/waiting_to_be_processed', :to => 'physical_files#waiting_to_be_processed', :as => :waiting_to_be_processed_physical_files
  get 'physical_files/:id/download(.:format)', :to => 'physical_files#download', :as => :download_physical_file
  resources :physical_files

  resources :search_statistics

  resources :site_statistics

  get 'feedbacks/list_by_userid',  :to => 'feedbacks#list_by_userid', :as => :list_by_userid_feedbacks
  get 'feedbacks/list_by_name',  :to => 'feedbacks#list_by_name', :as => :list_by_name_feedbacks
  get 'feedbacks/list_by_date',  :to => 'feedbacks#list_by_date', :as => :list_by_date_feedbacks
  get 'feedbacks/list_by_identifier',  :to => 'feedbacks#list_by_identifier', :as => :list_by_identifier_feedbacks
  get 'feedbacks/select_by_identifier',  :to => 'feedbacks#select_by_identifier', :as => :select_by_identifier_feedbacks
  post 'feedbacks/:id/convert_to_issue(.:format)', :to => 'feedbacks#convert_to_issue', :as => :convert_feedback_to_issue
  resources :feedbacks



  get 'contacts/list_by_type',  :to => 'contacts#list_by_type', :as => :list_by_type_contacts
  get 'contacts/list_by_name',  :to => 'contacts#list_by_name', :as => :list_by_name_contacts
  get 'contacts/list_by_date',  :to => 'contacts#list_by_date', :as => :list_by_date_contacts
  get 'contacts/list_by_identifier',  :to => 'contacts#list_by_identifier', :as => :list_by_identifier_contacts
  get 'contacts/select_by_identifier',  :to => 'contacts#select_by_identifier', :as => :select_by_identifier_contacts
  get  'contacts/:id(.:format)/report_error', :to => 'contacts#report_error', :as => :report_error_contact
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
  get  'manage_syndicates/select_action',  :to => 'manage_syndicates#select_action', :as => :select_action_manage_syndicates

  get  'manage_syndicates/:id/selected(.:format)',  :to => 'manage_syndicates#selected', :as => :selected_manage_syndicates
  get  'manage_syndicates/display_files_waiting_to_be_processed',  :to => 'manage_syndicates#display_files_waiting_to_be_processed', :as => :display_files_waiting_to_be_processed_manage_syndicates
  resources :manage_syndicates

  resources :csvfiles
  get 'csvfiles/:id/error(.:format)', :to => 'csvfiles#replace', :as => :replace_csvfile
  get 'csvfiles/:id/download(.:format)', :to => 'csvfiles#download', :as => :download_csvfile

  resources :freecen_parms
  get 'freecen_parms/:year/:chapman_code/download(.:format)', :to => 'freecen_parms#download', :as => :download_freecen_parms

  resources :freecen_pieces, except: :new
  get 'freecen_pieces/:chapman_code/:year/new', :to => 'freecen_pieces#new', :as => :new_freecen_piece
  get 'freecen_pieces/:year/select_new_county', :to => 'freecen_pieces#select_new_county', :as => :select_new_county_freecen_piece

  get 'freecen_coverage', :to => 'freecen_coverage#index', :as => :freecen_coverage
  get 'freecen_coverage/:chapman_code', :to => 'freecen_coverage#show', :as => :show_freecen_coverage
  get 'freecen_coverage/:chapman_code/:act', :to => 'freecen_coverage#show', :as => :show_edit_freecen_coverage
  get 'freecen_coverage_graph/:type/:chapman_code/:year', :to => 'freecen_coverage#graph', :as => :graph_freecen_coverage



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

  get 'userid_details/role', :to =>'userid_details#role', :as => :role_userid_detail
  get 'userid_details/person_roles', :to =>'userid_details#person_roles', :as => :person_roles_userid_detail
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
  get  'manage_counties/display_files_waiting_to_be_processed',  :to => 'manage_counties#display_files_waiting_to_be_processed', :as => :display_files_waiting_to_be_processed_manage_counties
  get  'manage_counties/selection',  :to => 'manage_counties#review_a_specific_batch', constraints: ManageCountiesReviewBatchConstraint
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
  get 'freereg_contents/select_places(.:format)', :to => 'freereg_contents#select_places', :as => :select_places_freereg_content
  resources :freereg_contents

  get 'churches/:id/rename', :to => 'churches#rename', :as => :rename_church
  get 'churches/:id/merge(.:format)', :to => 'churches#merge', :as => :merge_church
  get 'churches/:id/relocate(.:format)', :to => 'churches#relocate', :as => :relocate_church
  resources :churches

  get 'registers/:id/rename', :to => 'registers#rename', :as => :rename_register
  get 'registers/:id/merge(.:format)', :to => 'registers#merge', :as => :merge_register
  get 'registers/:id/relocate', :to => 'registers#relocate', :as => :relocate_register
  resources :registers

  resources :master_place_names

  get 'places/:id/approve', :to => 'places#approve', :as => :approve_place
  get 'places/:id/rename', :to => 'places#rename', :as => :rename_place
  get 'places/:id/merge(.:format)', :to => 'places#merge', :as => :merge_place
  get 'places/:id/relocate(.:format)', :to => 'places#relocate', :as => :relocate_place
  get 'places/for_search_form(.:format)', :to => 'places#for_search_form', :as => :places_for_search_form
  get 'places/for_freereg_content_form(.:format)', :to => 'places#for_freereg_content_form', :as => :places_for_freereg_content_form
  get 'places/for_freecen_piece_form(.:format)', :to => 'places#for_freecen_piece_form', :as => :places_for_freecen_piece_form
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
  resources :freereg1_csv_files

  resources :emendation_types

  resources :emendation_rules

  resources :search_names


  get 'search_records/:id/show_print_version(.:format)', :to => 'search_records#show_print_version', :as => :show_print_version_search_record
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

  resources :image_lists



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
