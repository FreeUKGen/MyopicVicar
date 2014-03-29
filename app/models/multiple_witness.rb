class MultipleWitness
  include Mongoid::Document
  field :witness_forename, type: String
  field :witness_surname, type: String
  
  embedded_in :freereg1_csv_entry
end