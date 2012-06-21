require 'chapman_code'
ActiveAdmin.register ImageList do
  show :title => :name do
    attributes_table do
      row :name
      row :chapman_code
      row :start_date
      row :difficulty
      row :created_at
    end
    h3 "Files"
    table_for image_list.image_files do
      column("Name") do |f|
        link_to f.display_name, admin_image_file_path(f)
      end
      column("Image") do |f|
        image_tag f.thumbnail_url
      end
    end
  end
  
  
  form do |f|
    f.inputs "Details" do
      f.input :name
      f.input :start_date
      f.input :difficulty, :as => :select, :collection => { "Beginner" => 0, "Intermediate" => 1, "Advanced" => 2 }
      f.input :chapman_code, :as => :select, :collection => ChapmanCode::select_hash_with_parenthetical_codes
    end
    f.buttons
  end

  


end
