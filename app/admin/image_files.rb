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
ActiveAdmin.register ImageFile do
  menu false
  actions :all, :except => :edit
  action_item({ :only => :show }) do
    link_to "Deskew", deskew_admin_image_file_path
  end
  action_item({ :only => :show }) do
    link_to "Rotate 90", rotate90_admin_image_file_path
  end
  action_item({ :only => :show }) do
    link_to "Rotate 270", rotate270_admin_image_file_path
  end
  action_item({ :only => :show }) do
    link_to "Negate", negate_admin_image_file_path
  end
  action_item({ :only => :show, :if => proc{ !image_file.original? } }) do
    link_to "Revert", revert_admin_image_file_path
  end

  show :title => :display_name do
    attributes_table do
      #row :name
      #row :path
      row :name do |imf|
        imf.display_name
      end
      row :directory do |imf|
        link_to imf.image_dir.name, admin_image_dir_path(imf.image_dir)
      end
      row :thumbnail_url
      row :image_url
      row :width
      row :height
      
    end
    h3 "Image"
    div do
      link_to image_tag(image_file.image_url, :style => "width: 100%"), image_file.image_url
    end
  end


  member_action :deskew  do    
    @image_file=ImageFile.find(params[:id])
    @image_file.deskew
    redirect_to admin_image_file_path
  end

  member_action :rotate90  do    
    @image_file=ImageFile.find(params[:id])
    @image_file.rotate(90)
    redirect_to admin_image_file_path
  end

  member_action :rotate270  do    
    @image_file=ImageFile.find(params[:id])
    @image_file.rotate(270)
    redirect_to admin_image_file_path
  end

  member_action :negate  do    
    @image_file=ImageFile.find(params[:id])
    @image_file.negate
    redirect_to admin_image_file_path
  end

  member_action :revert  do    
    @image_file=ImageFile.find(params[:id])
    @image_file.revert
    redirect_to admin_image_file_path
  end

  member_action :convert do
    # convert single images to an image list.
    # TODO: refactor this with the other convert method.
    @image_file = ImageFile.find(params[:id])
    puts "image file is #{@image_file.inspect}"
    il = ImageList.create(:name => @image_file.name, :image_file_ids => [ @image_file.id ])
    il.save!
    flash[:notice] = "Image list was successfully created."
    redirect_to admin_image_lists_path
  end

end
