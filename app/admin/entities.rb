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
ActiveAdmin.register Entity do
  actions :show
  menu false
  show :title => :name do |template|
    attributes_table do
      row :name
      row :description
      row :help
      row :resizeable
      row :width
      row :height
      row :bounds
      row :zoom
      row :created_at
      
    end
    h3 "Fields"
    table_for entity.fields do
      column :name
      column :kind
      column :field_key
      column :initial_value
      column :options
    end
  end
end
