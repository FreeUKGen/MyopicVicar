ActiveAdmin.register ImageUploadLog do
  menu false
  actions :show

  belongs_to :upload, :optional => true

  
  show :title => :file do   
    attributes_table do
      row :image_upload do |ul|
        iu = ul.image_upload
        link_to iu.name, admin_image_upload_path(iu)
      end
      row :file
      row :created_at
      row :updated_at
#      row :contents do |ul|
#        pre ul.read
#      end
    end
    h4 "Contents"
    pre image_upload_log.read

  end
end
