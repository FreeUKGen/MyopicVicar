ActiveAdmin.register AssetCollection, :as => "Book Part" do
  actions :show, :index, :edit, :delete

    
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
