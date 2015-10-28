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
  belongs_to :place

  # previous / next dwelling in census (not previous/next search result)
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

  # labels/vals for dwelling page header section (body in freecen_individuals)
  def self.dwelling_display_labels(year, chapman_code)
    #1841 doesn't have ecclesiastical parish or schedule number
    #Scotland doesn't have folio
    if '1841' == year
      if ChapmanCode::CODES['Scotland'].member?(chapman_code)
        return ['Census Year', 'County', 'Civil Parish', 'Piece', 'Enumeration District', 'Page', 'House Number', 'House or Street Name']
      end
      return ['Census Year', 'County', 'Civil Parish', 'Piece', 'Enumeration District', 'Folio', 'Page', 'House Number', 'House or Street Name']
    end
    if ChapmanCode::CODES['Scotland'].member?(chapman_code)
      return ['Census Year', 'County', 'Civil Parish', 'Ecclesiastical Parish', 'Piece', 'Enumeration District', 'Page', 'Schedule', 'House Number', 'House or Street Name']
    end
    ['Census Year', 'County', 'Civil Parish', 'Ecclesiastical Parish', 'Piece', 'Enumeration District', 'Folio', 'Page', 'Schedule', 'House Number', 'House or Street Name']
  end
  def dwelling_display_values(year, chapman_code)
    #1841 doesn't have ecclesiastical parish or schedule number
    #Scotland doesn't have folio
    disp_county = '' + ChapmanCode::name_from_code(chapman_code) + ' (' + chapman_code + ')'
    # self.place.place_name is currently identical to civil_parish
    if '1841' == year
      if ChapmanCode::CODES['Scotland'].member?(chapman_code)
        return [self.freecen1_vld_file.full_year, disp_county, self.civil_parish, self.freecen1_vld_file.piece, self.enumeration_district, self.page_number, self.house_number, self.house_or_street_name]
      end
      return [self.freecen1_vld_file.full_year, disp_county, self.civil_parish, self.freecen1_vld_file.piece, self.enumeration_district, self.folio_number, self.page_number, self.house_number, self.house_or_street_name]
    end
    if ChapmanCode::CODES['Scotland'].member?(chapman_code)
      return [self.freecen1_vld_file.full_year, disp_county, self.civil_parish, self.ecclesiastical_parish, self.freecen1_vld_file.piece, self.enumeration_district, self.folio_number, self.page_number, self.schedule_number, self.house_number, self.house_or_street_name]
    end
    [self.freecen1_vld_file.full_year, disp_county, self.civil_parish, self.ecclesiastical_parish, self.freecen1_vld_file.piece, self.enumeration_district, self.folio_number, self.page_number, self.schedule_number, self.house_number, self.house_or_street_name]
  end
end
