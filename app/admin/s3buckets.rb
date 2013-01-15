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
ActiveAdmin.register S3bucket do
  menu :priority => 1
  #menu :false  
  #actions :new, :except => :detail

  index do
    column "Name", :sortable => :name do |bucket|
      link_to bucket.name, admin_s3bucket_path(bucket)
    end
    column "Directories" do |bucket|
      bucket.prefixes.count
    end
    column :created_at
  end

  show :title => :name do 
    attributes_table do
      row :name
      row :created_at
    end
   
    h3 "Directories" 
    ul do
      s3bucket.directories.each do |dir|
        li link_to(dir, detail_admin_s3bucket_path('dir' => dir))
      end
    end

  end

  
  member_action :import, :method => :post  do    
    u = Upload.create(:name => params[:dir], :upload_path => "/tmp/myopicvicar/fbmd-images/#{params[:dir]}", :status => "importing")
    u.save(:validate => false)

    dir_name = params[:dir]
    upload_id = u.id
    FileUtils.mkdir_p "/tmp/myopicvicar/fbmd-images/#{dir_name}"
    files = []

    # Create a callback
    callback = Proc.new do |modified, added, removed|
      files << added unless added.empty?
      puts "files is #{files}"
      puts "number of files downloaded #{files.length}"
      u = Upload.find(upload_id)
      u.downloaded = files.length
      u.save
      # This proc will be called when there are changes.
    end

    listener = Listen.to("/tmp/myopicvicar/fbmd-images/#{dir_name}")
    listener.change(&callback) # convert the callback to a block and register it

    listener.start(false) # blocks execution


    system "rake s3bucket:import[#{params[:id]},#{params[:dir]},#{u.id}] &"
    redirect_to admin_uploads_path
  end

  member_action :detail  do    
    @s3bucket = S3bucket.find(params[:id])
    @dir = params[:dir]
    @page_title = @dir
    @files = @s3bucket.ls(@dir)
    #p params[:dir]
    #h3 "Files"
    #ul do
      #s3bucket.ls(params[:dir]).each
    #end
    #render :text => params.inspect
    #redirect_to admin_image_upload_path
  end

end
