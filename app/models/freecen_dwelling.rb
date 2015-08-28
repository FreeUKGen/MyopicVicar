class FreecenDwelling
  include Mongoid::Document
  field :entry_number, type: Integer
  field :deleted_flag, type: String
  field :dwelling_nummber, type: Integer
  field :civil_parish, type: String
  field :ecclesiastical_parish, type: String
  field :enumeration_district, type: String
  field :folio_number, type: String
  field :page_number, type: Integer
  field :schedule_number, type: String
  field :house_number, type: String
  field :house_or_street_name, type: String
  field :uninhabited_flag, type: String
  field :unoccupied_notes, type: String
  belongs_to :freecen1_vld_file
  has_many :freecen_individuals
end
