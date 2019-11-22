class BestGuessMarriage < ActiveRecord::Base
  establish_connection FREEBMD_DB
  self.table_name = 'BestGuessMarriages'
  belongs_to :BestGuess, foreign_key: :RecordTypeID#, :volume, :page, :QuarterNumber
end