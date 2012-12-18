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
ActiveAdmin.register ImageUploadLog do
  menu false
  actions :show

  belongs_to :upload, :optional => true

  
  show :title => :file do   
    attributes_table do
      row :image_upload do |ul|
        iu = ul.upload
        link_to iu.name, admin_upload_path(iu)
      end
      row :file
      row :created_at
      row :updated_at
#      row :contents do |ul|
#        pre ul.read
#      end
    end
    h4 "Contents"
    pre image_upload_log.read

  end
end
