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
ActiveAdmin.register_page "Dashboard" do
  menu :priority => 1, :label => proc{ I18n.t("active_admin.dashboard") }

  content :title => proc{ I18n.t("active_admin.dashboard") } do
    #div :class => "blank_slate_container", :id => "dashboard_default_message" do
      #span :class => "blank_slate" do
	#span I18n.t("active_admin.dashboard_welcome.welcome")
	#small I18n.t("active_admin.dashboard_welcome.call_to_action")
      #end
    #end

    columns do
      column do
	panel "Recent Activity" do
	  h3 "Uploads"
	  ul do
	    Upload.order_by(:updated_at.desc).limit(5).each do |iu|
	      li link_to(iu.name, admin_upload_path(iu))
	    end
	  end
	  h3 "Image Lists"
	  ul do
	    ImageList.order_by(:updated_at.desc).limit(5).each do |il|
	      li link_to(il.name, admin_image_list_path(il))
	    end
	  end
	end
      end


      column do
	panel "System Stats" do
	  table do
	    tr do
	      td "Uploads"
	      td Upload.count
	    end
	    tr do
	      td "Directories"
	      td ImageDir.count
	    end
	    tr do
	      td "Image Files"
	      td ImageFile.count
	    end
	    tr do
	      td "Image Lists"
	      td Upload.count
	    end
	    tr do
	      td APP_CONFIG['asset_collection_name']
	      td AssetCollection.count
	    end
	    tr do
	      td "Pages"
	      td Asset.count
	    end
	  end
	end
      end
    end
  end
end
