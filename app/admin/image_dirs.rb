ActiveAdmin.register ImageDir do
  menu false
  actions :show

  belongs_to :image_upload, :optional => true

  show :title => :name do
    attributes_table do
      row :upload do |ud|
        link_to ud.image_upload.name, admin_image_upload_path(ud.image_upload)
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
      column("Image") do |f|
        image_tag f.thumbnail_url
      end
    end
  end
end
