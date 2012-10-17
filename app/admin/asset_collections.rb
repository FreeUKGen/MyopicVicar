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
ActiveAdmin.register AssetCollection, :as => APP_CONFIG['asset_collection_name'] do
  menu :priority => 4
  actions :show, :index, :edit, :delete


  index do
    column "Title", :sortable => [:name, :chapman_code] do |ac|
      link_to ac.title, admin_register_path(ac)
    end
    column :chapman_code
  end

    
  show :title => :title do |asset_collection|
    attributes_table do
      row :title
      row :author
      row :extern_ref
      row :chapman_code
    end
    h3 "Pages"
    table_for asset_collection.assets do
      column("Name") do |a|
        link_to(a.location, admin_asset_path(a))
      end
    end
  end

end
