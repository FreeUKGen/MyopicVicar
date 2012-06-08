ActiveAdmin.register ImageUpload do

  # prototype had this:
  index do
    column "Name", :sortable => :name do |iu|
      link_to iu.name, admin_image_upload_path(iu)
    end
    column :upload_path
    column :created_at
  end
  
  show :title => :name do |ad|
    
    attributes_table do
      row :name
      row :upload_path
      row :working_dir
      row :created_at
    end

#    h3 "Directories"
#  
#    table_for image_upload.image_dirs do
#      column("Name") { |dir| dir.name }
#      column("Path") { |dir| dir.path }
#    end
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
