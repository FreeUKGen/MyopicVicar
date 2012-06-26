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
      column :name
      column :kind
      column :field_key
      column :initial_value
      column :options
    end
  end
end
