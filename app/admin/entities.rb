ActiveAdmin.register Entity do
  actions :show
  menu false
  show :title => :name do |template|
    attributes_table do
      row :name
      row :description
      row :help
      row :resizeable
      row :width
      row :height
      row :bounds
      row :zoom
      row :created_at
      
    end
    h3 "Fields"
    table_for entity.fields do
      column("Name") do |f|
        link_to f.name, admin_field_path(f)
      end
    end
  end
end
