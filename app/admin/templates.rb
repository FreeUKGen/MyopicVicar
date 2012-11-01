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
ActiveAdmin.register Template do
  menu :priority => 5
#  actions :show, :index
  
  index do
    column "Name", :sortable => [:name, :chapman_code] do |t|
      link_to t.name, admin_template_path(t)
    end
    column :description
    column :project
    column :default_zoom
    column :created_at
  end

  
  show :title => :name do |template|
    attributes_table do
      row :name
      row :description
      row :project
      row :default_zoom
      row :created_at      
    end
    h3 "Tabs"
    table_for template.entities do
      column("Name") do |e|
        link_to e.name, admin_entity_path(e)
      end
    end
    div link_to "Add Tab", new_admin_entity_path()
    
  end

end
