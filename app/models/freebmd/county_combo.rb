class CountyCombo < ActiveRecord::Base
  establish_connection FREEBMD_DB
  self.pluralize_table_names = false
  self.table_name = 'CountyCombos'
end