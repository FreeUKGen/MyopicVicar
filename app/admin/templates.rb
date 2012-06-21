ActiveAdmin.register Template do
  actions :show, :index
  show :title => :name do |template|
    attributes_table do
      row :name
      row :description
      row :project
      row :default_zoom
      row :created_at
      
    end
    h3 "Tabs"
    table_for template.entities do
      column("Name") do |e|
        link_to e.name, admin_entity_path(e)
      end
    end
  end

end
