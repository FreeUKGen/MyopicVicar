module Freecen2CivilParishesHelper
  def civil_parish_year(civil_parish, year)
    freecen2_civil_parish = Freecen2CivilParish.find_by(chapman_code: session[:chapman_code], name: civil_parish, year: year)
    if freecen2_civil_parish.present? && freecen2_civil_parish.year == year
      link_to 'Yes', freecen2_civil_parish_path(freecen2_civil_parish.id, type: @type), method: :get, class: 'btn   btn--small', title:' Displays all of the information about this specific Civil Parish'
    else
      'No'
    end
  end

  def civil_parish_index_link(chapman_code, year)
    link_to "#{year}", freecen2_civil_parishes_chapman_year_index_path(chapman_code: "#{chapman_code}", year: "#{year}", type: @type), method: :get, class: 'btn   btn--small', title: 'List of Civil Parishes for this year'
  end

  def civil_place_link(place)
    if place.present?
      link_to "#{place.place_name}", freecen2_place_path(place.id), class: 'btn   btn--small', title: ' Displays all of the information about the place to which this Civil Parish is linked'
    else
      'There is no place'
    end
  end

  def civil_district_link(civil_parish)
    piece = civil_parish.freecen2_piece
    district = piece.freecen2_district
    link_to "#{district.name}", freecen2_district_path(district), class: 'btn   btn--small', title:' Displays all of the information about the District to which this Sub District (Piece) is linked'
  end

  def civil_piece_link(civil_parish)
    piece = civil_parish.freecen2_piece
    link_to "#{piece.name}", freecen2_piece_path(piece), class: 'btn   btn--small', title:' Displays all of the information about the Sub District (Piece) to which this Civil Parish is linked'
  end

  def civil_district_name(civil_parish)
    piece = civil_parish.freecen2_piece
    district = piece.freecen2_district
    "#{district.name}"
  end

  def civil_piece_name(civil_parish)
    piece = civil_parish.freecen2_piece
    "#{piece.name}"
  end

end
