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
 
 
  resources :place_caches


  resources :manage_syndicates   
  
  resources :csvfiles
  get 'csvfiles/:id/error(.:format)', :to => 'csvfiles#replace', :as => :replace_csvfile
  get 'csvfiles/:id/download(.:format)', :to => 'csvfiles#download', :as => :download_csvfile

  get 'manage_freeregs', :to => 'manage_freeregs#index', :as => :manage_freeregs
  get 'manage_freereg/all', :to => 'manage_freeregs#all', :as => :all_manage_freereg
  


  resources :countries



  resources :counties


  resources :my_saved_searches


  resources :manage_resources
get 'userid_details/:id/change_password', :to =>'userid_details#change_password', :as => :change_password_userid_detail 
  get 'userid_details/researcher_registration', :to =>'userid_details#researcher_registration', :as => :researcher_registration_userid_detail 
  get 'userid_details/transcriber_registration', :to =>'userid_details#transcriber_registration', :as => :transcriber_registration_userid_detail 
  get 'userid_details/technical_registration', :to =>'userid_details#technical_registration', :as => :technical_registration_userid_detail 
  get 'userid_details/general', :to =>'userid_details#general', :as => :general_userid_detail 
  get 'userid_details/:id/disable(.:format)', :to => 'userid_details#disable', :as => :disable_userid_detail
  get 'userid_details/:id/syndicate(.:format)', :to => 'userid_details#syndicate', :as => :syndicate_userid_detail
  get 'userid_details/my_own',  :to => 'userid_details#my_own', :as => :my_own_userid_detail
  get 'userid_details/all', :to => 'userid_details#all', :as => :all_userid_detail
  
  resources :userid_details

 get  'manage_counties/select',  :to => 'manage_counties#select', :as => :select_manage_county
  resources :manage_counties

  resources :syndicates

  resources :coordinators

  resources :alias_place_churches

  get 'freereg_contents/:id/show(.:format)', :to => 'freereg_contents#show', :as => :show_freereg_content
  get 'freereg_contents/:id/show_church(.:format)', :to => 'freereg_contents#show_church', :as => :show_church
  get 'freereg_contents/:id/show_register(.:format)', :to => 'freereg_contents#show_register', :as => :show_register
  get 'freereg_contents/:id/show_decade(.:format)', :to => 'freereg_contents#show_decade', :as => :show_decade
  
  resources :freereg_contents

  resources :churches

  resources :registers

  resources :master_place_names

  get 'places/:id/relocate(.:format)', :to => 'places#relocate', :as => :relocate_place
  get 'places/for_search_form(.:format)', :to => 'places#for_search_form', :as => :places_for_search_form
  resources :places
  
  resources :church_names

  resources :toponyms
 get 'freereg1_csv_entries/:id/error(.:format)', :to => 'freereg1_csv_entries#error', :as => :error_freereg1_csv_entry
 get 'freereg1_csv_entries/select_page', :to => 'freereg1_csv_entries#select_page', :as => :select_page_freereg1_csv_entry
 post 'freereg1_csv_entries/select_page', :to => 'freereg1_csv_entries#selected_page', :as => :selected_page_freereg1_csv_entry
  resources :freereg1_csv_entries

 get 'freereg1_csv_files/:id/lock(.:format)', :to => 'freereg1_csv_files#lock', :as => :lock_freereg1_csv_file
 get 'freereg1_csv_files/:id/error(.:format)', :to => 'freereg1_csv_files#error', :as => :error_freereg1_csv_file
 get 'freereg1_csv_files/my_own',  :to => 'freereg1_csv_files#my_own', :as => :my_own_freereg1_csv_file
 get 'freereg1_csv_files/:id/by_userid',  :to => 'freereg1_csv_files#by_userid', :as => :by_userid_freereg1_csv_file

  resources :freereg1_csv_files

  resources :emendation_types

  resources :emendation_rules

  resources :search_names

  resources :search_records

  get 'search_queries/:id/about(.:format)', :to => 'search_queries#about', :as => :about_search_query
  post 'search_queries/:id/remember(.:format)', :to => 'search_queries#remember', :as => :remember_search_query
  resources :search_queries

  resources :s3buckets

  resources :fields

  resources :templates

  resources :entities

  resources :asset_collections

  resources :assets

  resources :image_lists
  
  #root :to => 'search_queries#index'
  
  # This line mounts Refinery's routes at the root of your application.
  # This means, any requests to the root URL of your application will go to Refinery::PagesController#home.
  # If you would like to change where this extension is mounted, simply change the :at option to something different.
  #
  # We ask that you don't use the :as option here, as Refinery relies on it being the default of "refinery"
 
  mount Refinery::Core::Engine, :at => '/'

  ActiveAdmin.routes(self)

  devise_for :admin_users, ActiveAdmin::Devise.config


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
  # root :to => "welcome#index"
  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
