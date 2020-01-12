class BestGuessMarriage < ActiveRecord::Base
  establish_connection FREEBMD_DB
  self.table_name = 'BestGuessMarriages'
  belongs_to :best_guess, class_name: '::BestGuess', foreign_key: 'RecordNumber'
end