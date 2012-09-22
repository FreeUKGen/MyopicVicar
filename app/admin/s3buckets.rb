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
    system "rake import S3_BUCKET_ID=#{params[:id]} DIR_NAME=#{params[:dir]} &"
    redirect_to admin_uploads_path, :notice => "Importing."
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
