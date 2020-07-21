module Freecen2DistrictHelper
  def district_year(district, year)
    freecen2_district = Freecen2District.find_by(chapman_code: session[:chapman_code], name: district, year: year)
    if freecen2_district.present? && freecen2_district.year == year
      link_to 'Yes', freecen2_district_path(freecen2_district.id, type: 'index')
    else
      'No'
    end
  end
end
