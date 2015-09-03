class FreecenIndividual
  include Mongoid::Document
  field :sequence_in_household, type: Integer
  field :individual_flag, type: String
  field :surname, type: String
  field :forenames, type: String
  field :name_flag, type: String
  field :relationship, type: String
  field :marital_status, type: String
  field :sex, type: String
  field :age, type: String
  field :age_unit, type: String
  field :detail_flag, type: String
  field :occupation, type: String
  field :occupation_flag, type: String
  field :birth_county, type: String
  field :birth_place, type: String
  field :verbatim_birth_county, type: String
  field :verbatim_birth_place, type: String
  field :birth_place_flag, type: String
  field :disability, type: String
  field :language, type: String
  field :notes, type: String
  belongs_to :freecen_dwelling
  belongs_to :freecen1_vld_entry
  
  index(freecen_dwelling_id:1)
end
