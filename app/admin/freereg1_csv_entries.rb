ActiveAdmin.register Freereg1CsvEntry do
  menu false
  actions :show

  belongs_to :freereg1_csv_file, :optional => false
  
end
