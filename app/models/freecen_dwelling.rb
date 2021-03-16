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
  belongs_to :freecen1_vld_file, index: true
  has_many :freecen_individuals
  belongs_to :place, index: true
  belongs_to :freecen_piece, index: true
  delegate :piece_number, :year, :chapman_code, to: :freecen_piece, prefix: true
  delegate :place_name, to: :place#, prefix: true

  index({freecen_piece_id: 1,dwelling_number: 1},{background: true})


  # ################################################################################ instance

  # previous / next dwelling in census (not previous/next search result)
  def prev_next_dwelling_ids
    prev_id = nil
    next_id = nil
    idx = self.dwelling_number.to_i
    pc_id = self.freecen_piece_id
    if idx && idx >= 0
      prev_dwel = FreecenDwelling.where(freecen_piece_id: pc_id, dwelling_number: (idx - 1)).first
      prev_id = prev_dwel[:_id] unless prev_dwel.nil?
      next_dwel = FreecenDwelling.where(freecen_piece_id: pc_id, dwelling_number: (idx + 1)).first
      next_id = next_dwel[:_id] unless next_dwel.nil?
    end
    [prev_id, next_id]
  end

  # labels/vals for dwelling page header section (body in freecen_individuals)
  def self.dwelling_display_labels(year, chapman_code)
    #1841 doesn't have ecclesiastical parish or schedule number
    #Scotland doesn't have folio
    if '1841' == year
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        return ['Census', 'County', 'District', 'Civil Parish', 'Piece', 'Enumeration District', 'Page', 'House Number', 'House or Street Name']
      end
      return ['Census', 'County', 'District', 'Civil Parish', 'Piece', 'Enumeration District', 'Folio', 'Page', 'House Number', 'House or Street Name']
    end
    if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
      return ['Census', 'County', 'District', 'Civil Parish', 'Ecclesiastical Parish', 'Piece', 'Enumeration District', 'Folio', 'Page', 'Schedule', 'House Number', 'House or Street Name']
    end
    ['Census', 'County', 'District', 'Civil Parish', 'Ecclesiastical Parish', 'Piece', 'Enumeration District', 'Folio', 'Page', 'Schedule', 'House Number', 'House or Street Name']
  end
  def dwelling_display_values(year, chapman_code)
    #1841 doesn't have ecclesiastical parish or schedule number
    #Scotland doesn't have folio
    disp_county = '' + ChapmanCode::name_from_code(chapman_code) + ' (' + chapman_code + ')' unless chapman_code.nil?
    if '1841' == year
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        return [self.freecen_piece.year, disp_county, self.place.place_name, self.civil_parish, self.freecen_piece.piece_number.to_s, self.enumeration_district, self.page_number, self.house_number, self.house_or_street_name]
      end
      return [self.freecen_piece.year, disp_county, self.place.place_name, self.civil_parish, self.freecen_piece.piece_number.to_s, self.enumeration_district, self.folio_number, self.page_number, self.house_number, self.house_or_street_name]
    end
    if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
      return [self.freecen_piece.year, disp_county, self.place.place_name, self.civil_parish, self.ecclesiastical_parish, self.freecen_piece.piece_number.to_s, self.enumeration_district, self.folio_number, self.page_number, self.schedule_number, self.house_number, self.house_or_street_name]
    end
    [self.freecen_piece.year, disp_county, self.place.place_name, self.civil_parish, self.ecclesiastical_parish, self.freecen_piece.piece_number.to_s, self.enumeration_district, self.folio_number, self.page_number, self.schedule_number, self.house_number, self.house_or_street_name]
  end
end
