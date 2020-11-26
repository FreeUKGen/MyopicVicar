module Freecen2DistrictHelper
  def district_year(district, year)
    freecen2_district = Freecen2District.where(chapman_code: session[:chapman_code], name: district, year: year).exists?
    if freecen2_district
      link_to 'Yes', locate_freecen2_district_path(chapman_code: session[:chapman_code], name: district, year: year, type: @type), method: :get, class: 'btn   btn--small', title:' Displays all of the information about this specific District'
    else
      'No'
    end
  end

  def district_index_link(chapman_code, year)
    link_to "#{year}", freecen2_districts_chapman_year_index_path(chapman_code: "#{chapman_code}", year: "#{year}", type: @type), method: :get, class: 'btn   btn--small', title: 'List of Districts for this year'
  end

  def list_pieces(freecen2_district)
    link_to "#{@freecen2_pieces_name}", freecen2_pieces_district_index_path(freecen2_district_id: freecen2_district.id, type: @type), class: 'btn   btn--small', title: 'List of the Pieces that belong to this District'
  end

  def district_place_link(place)
    if place.present?
      link_to "#{place.place_name}", freecen2_place_path(place.id), class: 'btn   btn--small', title: ' Displays all of the information about the place to which this District is linked'
    else
      'There is no place'
    end
  end
end
