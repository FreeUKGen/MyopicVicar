ActiveAdmin.register AssetCollection, :as => APP_CONFIG['asset_collection_name'] do
  menu :priority => 4
  actions :show, :index, :edit, :delete


  index do
    column "Title", :sortable => [:name, :chapman_code] do |ac|
      link_to ac.title, admin_book_part_path(ac)
    end
    column :chapman_code
  end

    
  show :title => :title do |asset_collection|
    attributes_table do
      row :title
      row :author
      row :extern_ref
      row :chapman_code
    end
    h3 "Pages"
    table_for asset_collection.assets do
      column("Name") do |a|
        link_to(a.location, admin_asset_path(a))
      end
    end
  end

end
