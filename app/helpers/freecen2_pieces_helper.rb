module Freecen2PiecesHelper

  def tna(number)
    link_to 'TNA', "https://discovery.nationalarchives.gov.uk/browse/r/h/#{number}", target: :_blank
  end

  def district_link(district)
    link_to "#{district.name}", freecen2_district_path(district)
  end

  def civil_link(piece)
    link_to "#{piece.civil_parish_names}", freecen2_civil_parishes_path(piece_id: piece.id)
  end

  def csv_files(piece)
    number = piece.freecen_csv_files.length
    link_to "#{number}", freecen_csv_files_path(piece_id: piece.id, type: 'piece')
  end

  def individual_civil_link(parish)
    link_to "#{parish.name} #{parish.add_hamlet_township_names}", freecen2_civil_parish_path(parish.id)
  end
  def place_link(place)
    if place.present?
      link_to "#{place.place_name}", freecen2_place_path(place.id)
    else
      'There is no place'
    end

  end

  def piece_year(piece, year)
    freecen2_piece = Freecen2Piece.find_by(chapman_code: session[:chapman_code], name: piece, year: year)
    if freecen2_piece.present? && freecen2_piece.year == year
      link_to 'Yes', freecen2_piece_path(freecen2_piece.id, type: 'index')
    else
      'No'
    end
  end
end
