module Freecen2PiecesHelper

  def tna(number)
    link_to 'The National Archive', "https://discovery.nationalarchives.gov.uk/browse/r/h/#{number}", target: :_blank, class: 'btn   btn--small', title:'Access to The National Archive'
  end

  def district_link(district)
    link_to "#{district.name}", freecen2_district_path(district), class: 'btn   btn--small', title:' Displays all of the information about the District to which this Sub District (Piece) is linked'
  end

  def civil_link(piece)
    link_to "Link to Civil Parishes", index_for_piece_freecen2_civil_parishes_path(piece_id: piece.id, type: @type), class: 'btn   btn--small', title:' Displays a list of the Civil Parishes which belong to this Sub District (Piece)'
  end

  def csv_files(piece)
    if piece.freecen_csv_files.present?
      files = []
      piece.freecen_csv_files.each do |file|
        files << file.file_name
      end
      link_to "#{files}", freecen_csv_files_path, class: 'btn   btn--small', title:'Csv files for this Piece'
    else
      'There are no csv files'
    end
  end

  def individual_civil_link(parish)
    link_to "#{parish.name} #{parish.add_hamlet_township_names}", freecen2_civil_parish_path(parish.id)
  end
  def place_link(place)
    if place.present?
      link_to "#{place.place_name}", freecen2_place_path(place.id), class: 'btn   btn--small', title: ' Displays all of the information about the place to which this Sub District (Piece) is linked'
    else
      'There is no place'
    end
  end

  def piece_year(piece, year)
    freecen2_piece = Freecen2Piece.find_by(chapman_code: session[:chapman_code], name: piece, year: year)
    if freecen2_piece.present? && freecen2_piece.year == year
      link_to 'Yes', freecen2_piece_path(freecen2_piece.id, type: @type), method: :get, class: 'btn   btn--small', title: ' Displays all of the information about this specific Sub District (Piece)'
    else
      'No'
    end
  end

  def piece_index_link(chapman_code, year)
    link_to "#{year}", freecen2_pieces_chapman_year_index_path(chapman_code: "#{chapman_code}", year: "#{year}"), method: :get, class: 'btn   btn--small', title: 'List of Sub Districts (Pieces) for this year'
  end
end
