class FreecenDwelling
  include Mongoid::Document
  field :deleted_flag, type: String
  field :dwelling_number, type: Integer
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

  def prev_next_dwelling_ids
    prev_id = nil
    next_id = nil
    numDwellings = self.freecen1_vld_file.freecen_dwellings.length
    idx = self.dwelling_number
    if idx > 0
      prev_dwel = self.freecen1_vld_file.freecen_dwellings.where(dwelling_number: idx - 1).only(:FreecenDwelling_id).first
      prev_id = prev_dwel[:_id] unless prev_dwel.nil?
    end
    if idx < numDwellings - 1
      next_dwel = self.freecen1_vld_file.freecen_dwellings.where(dwelling_number: idx + 1).only(:FreecenDwelling_id).first
      next_id = next_dwel[:_id] unless next_dwel.nil?
    end
    [prev_id, next_id]
  end
end
