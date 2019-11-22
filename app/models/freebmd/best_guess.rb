class BestGuess < ActiveRecord::Base
  establish_connection FREEBMD_DB
  self.pluralize_table_names = false
  self.table_name = 'BestGuess'
  has_many :BestGuessMarriage, foreign_key: :RecordTypeID#, :volume, :page, :QuarterNumber
  extend SharedSearchMethods
end