class BestGuessMarriage < FreebmdDbBase
  self.table_name = 'BestGuessMarriages'
  belongs_to :best_guess, class_name: '::BestGuess', foreign_key: 'RecordNumber'
end