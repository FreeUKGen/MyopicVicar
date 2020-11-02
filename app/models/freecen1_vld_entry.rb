class Freecen1VldEntry
  include Mongoid::Document
  field :age, type: String
  field :age_unit, type: String
  field :birth_county, type: String
  field :birth_place, type: String
  field :birth_place_flag, type: String
  field :civil_parish, type: String
  field :deleted_flag, type: Boolean
  field :detail_flag, type: String
  field :disability, type: String
  field :dwelling_number, type: Integer
  field :ecclesiastical_parish, type: String
  field :enumeration_district, type: String
  field :folio_number, type: String
  field :forenames, type: String
  field :house_number, type: String
  field :house_or_street_name, type: String
  field :individual_flag, type: String
  field :language, type: String
  field :marital_status, type: String
  field :name_flag, type: String
  field :notes, type: String
  field :occupation, type: String
  field :occupation_flag, type: String
  field :page_number, type: Integer
  field :relationship, type: String
  field :schedule_number, type: String
  field :sequence_in_household, type: Integer
  field :sex, type: String
  field :surname, type: String
  field :uninhabited_flag, type: String
  field :unoccupied_notes, type: String
  field :verbatim_birth_county, type: String
  field :verbatim_birth_place, type: String

  belongs_to :freecen1_vld_file, index: true
end
