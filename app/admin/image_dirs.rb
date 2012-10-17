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
ActiveAdmin.register ImageDir do
  menu false
  actions :show

  action_item({ :only => :show }) do
    link_to "Deskew", deskew_admin_image_dir_path
  end
  action_item({ :only => :show }) do
    link_to "Rotate 90", rotate90_admin_image_dir_path
  end
  action_item({ :only => :show }) do
    link_to "Rotate 270", rotate270_admin_image_dir_path
  end
  action_item({ :only => :show }) do
    link_to "Negate", negate_admin_image_dir_path
  end
  action_item({ :only => :show }) do
    link_to "Revert", revert_admin_image_dir_path
  end
  action_item({ :only => :show }) do
    link_to "Convert", convert_admin_image_dir_path
  end


  belongs_to :upload, :optional => true

  show :title => :name do
    attributes_table do
      row :upload do |ud|
        link_to ud.upload.name, admin_upload_path(ud.upload)
      end
      row :name
      row :path
      row :created_at
    end

    h3 "Files"
    table_for image_dir.image_file do
      column("Name") do |f|
        link_to f.display_name, admin_image_file_path(f)
      end
      column("Action") do |f|
	link_to "Start a new Image List with this file", convert_admin_image_file_path(f)
      end
      column("Image") do |f|
        link_to(image_tag(f.thumbnail_url), admin_image_file_path(f))
      end
    end
  end
  
  member_action :convert do
    @image_dir=ImageDir.find(params[:id])
    logger.debug("Converting to image list")
    image_list = @image_dir.convert_to_image_list
    logger.debug("Converted to image list #{image_list.inspect}")
    redirect_to admin_image_list_path(image_list)
  end
  
  member_action :deskew  do    
    @image_dir=ImageDir.find(params[:id])
    @image_dir.image_file.each { |f| f.deskew }
    redirect_to admin_image_dir_path
  end

  member_action :rotate90  do    
    @image_dir=ImageDir.find(params[:id])
    @image_dir.image_file.each { |f| f.rotate(90) }
    redirect_to admin_image_dir_path
  end

  member_action :rotate270  do    
    @image_dir=ImageDir.find(params[:id])
    @image_dir.image_file.each { |f| f.rotate(270) }
    redirect_to admin_image_dir_path
  end

  member_action :negate  do    
    @image_dir=ImageDir.find(params[:id])
    @image_dir.image_file.each { |f| f.negate }
    redirect_to admin_image_dir_path
  end

  member_action :revert  do    
    @image_dir=ImageDir.find(params[:id])
    @image_dir.image_file.each { |f| f.revert }
    redirect_to admin_image_dir_path
  end

end
