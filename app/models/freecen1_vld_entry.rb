class Freecen1VldEntry
  include Mongoid::Document
  field :entry_number, type: Integer
  field :deleted_flag, type: Boolean
  field :household_number, type: Integer
  field :sequence_in_household, type: Integer
  field :civil_parish, type: String
  field :ecclesiastical_parish, type: String
  field :enumeration_district, type: String
  field :folio_number, type: String
  field :page_number, type: Integer
  field :schedule_number, type: String
  field :house_number, type: String
  field :house_or_street_name, type: String
  field :uninhabited_flag, type: String
  field :unnocupied_notes, type: String
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
  belongs_to :freecen1_vld_file, index: true
end
