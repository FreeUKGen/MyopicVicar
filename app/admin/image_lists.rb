require 'chapman_code'
ActiveAdmin.register ImageList do
  action_item({ :only => :show }) do
    link_to "Publish", publish_admin_image_list_path
  end


   index do
    column "Name", :sortable => :name do |il|
      link_to il.name, admin_image_list_path(il)
    end
    column :chapman_code
    column :difficulty
    column :created_at
  end

  
  show :title => :name do
    attributes_table do
      row :name
      row :chapman_code
      row :start_date
      row :template do |il|
        t = Template.find(il.template)
        t.name if t
      end
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
      f.input :template, :as => :select, :collection => Template.all
    end
    f.buttons
  end

  
  member_action :publish do
    @image_list=ImageList.find(params[:id])
    if @image_list.template.blank? 
      flash[:error] = "Template is required before an image list may be published."
      redirect_to edit_admin_image_list_path(@image_list)
    else
      flash[:notice] = "Image list #{@image_list.name} is now published for transcription."
      asset_collection = @image_list.publish_to_asset_collection
      redirect_to admin_book_part_path(asset_collection)
    end
#    logger.debug("Converting to image list")
#    image_list = @image_dir.convert_to_image_list
#    logger.debug("Converted to image list #{image_list.inspect}")
#    redirect_to admin_image_list_path(image_list)
  end


end
