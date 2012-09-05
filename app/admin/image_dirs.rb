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
        link_to ud.image_upload.name, admin_upload_path(ud.image_upload)
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
