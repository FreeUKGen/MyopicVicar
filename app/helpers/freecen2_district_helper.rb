module Freecen2DistrictHelper
  def district_year(district, year)
    freecen2_district = Freecen2District.where(chapman_code: session[:chapman_code], name: district, year: year).exists?
    if freecen2_district
      link_to 'Yes', locate_freecen2_district_path(chapman_code: session[:chapman_code], name: district, year: year, type: @type), method: :get, class: 'btn   btn--small'
    else
      'No'
    end
  end

  def district_index_link(chapman_code, year)
    link_to "#{year}", freecen2_districts_chapman_year_index_path(chapman_code: "#{chapman_code}", year: "#{year}", type: @type), method: :get, class: 'btn   btn--small'
  end

  def list_pieces(freecen2_district)
    link_to "#{@freecen2_pieces_name}", freecen2_pieces_district_index_path(freecen2_district_id: freecen2_district.id, type: @type)
  end
end
