ActiveAdmin.register ImageFile do
  menu false
  show :title => :display_name do
    attributes_table do
#      row :name
#      row :path
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
      image_tag image_file.image_url
    end
  end


end
