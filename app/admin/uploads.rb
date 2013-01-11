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
ActiveAdmin.register Upload do

  menu :priority => 2

  actions :show, :index, :new, :create
  action_item({ :only => :show, :if => proc{ upload.status == Upload::Status::NEW } }) do
    link_to "Process", process_upload_admin_upload_path
  end
  action_item({ :only => :index }) do
    link_to "Import From S3", admin_s3buckets_path
    #"Import from S3"
  end



  # prototype had this:
  index do
    column "Name", :sortable => :name do |iu|
      link_to iu.name, admin_upload_path(iu)
    end
    column :upload_path
    column :created_at
    column :status do |iu|
      status_tag iu.status
    end
  end
  
  show :title => :name do |ad|
    attributes_table do
      row :name
      row :upload_path
      row :status
      row :working_dir
      row :created_at
      row :total_files
      row :downloaded
    end

    h3 "Logs"
    table_for upload.image_upload_log do
      column("File") do 
        |lf| link_to lf.file, admin_image_upload_log_path(lf) 
      end
      column("Created") do 
        |lf| lf.created_at 
      end
      column("Last Updated") do 
        |lf| lf.updated_at 
      end
    end
    
    h3 "Directories" 
    table_for upload.image_dir do
      column("Name") do |dir| 
        link_to dir.name, admin_image_dir_path(dir) 
      end
      column("Path") { |dir| dir.path }
    end
  end

  
  member_action :import_from_aws do    
#      @image_upload = Upload.find(params[:id])
#      @image_upload.process_upload
      redirect_to admin_upload_path
#      redirect_to admin_s3buckets_path
  end


  member_action :process_upload  do    
    system "rake process_upload UPLOAD_ID=#{params[:id]} &"
    redirect_to admin_upload_path, :notice => "Processing."
  end



# docs has this:
#    form do |f|
#      f.inputs "Details" do
#        f.input :title
#        f.input :published_at, :label => "Publish Post At"
#        f.input :category
#      end
#      f.inputs "Content" do
#        f.input :body
#      end
#      f.buttons
#    end


  form do |f|
    f.inputs "Image Upload" do
      f.input :name
      f.input :upload_path
      
      f.buttons
    end
  end
  
  
end
