class BestGuess < ActiveRecord::Base
  self.pluralize_table_names = false
  self.table_name = 'BestGuess'
  extend SharedSearchMethods
end