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
  resources :freereg_contents
  get 'freereg_contents/:id/show(.:format)', :to => 'freereg_contents#show', :as => :show_freereg_content
  get 'freereg_contents/:id/show_church(.:format)', :to => 'freereg_contents#show_church', :as => :show_church
  get 'freereg_contents/:id/show_decade(.:format)', :to => 'freereg_contents#show_decade', :as => :show_decade
  resources :churches


  resources :registers


  resources :places

  resources :church_names

  resources :toponyms

  resources :freereg1_csv_entries

  resources :freereg1_csv_files

  resources :emendation_types

  resources :emendation_rules

  resources :search_names

  resources :search_records

  resources :search_queries

  resources :s3buckets

  resources :fields

  resources :templates

  resources :entities

  resources :asset_collections

  resources :assets

  resources :image_lists
  root :to => 'search_queries#index'

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
