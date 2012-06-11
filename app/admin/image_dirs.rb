ActiveAdmin.register ImageDir do
  menu false
  actions :show

  belongs_to :image_upload, :optional => true

  show :title => :name do
    attributes_table do
      row :name
      row :path
      row :created_at
    end

    h3 "Files"
    table_for image_dir.image_file do
      column("Name") do |f|
        f.name
      end
    end
  end
end
