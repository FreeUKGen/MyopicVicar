module Freecen2CivilParishesHelper
  def civil_parish_year(civil_parish, year)
    freecen2_civil_parish = Freecen2CivilParish.find_by(chapman_code: session[:chapman_code], name: civil_parish, year: year)
    if freecen2_civil_parish.present? && freecen2_civil_parish.year == year
      link_to 'Yes', freecen2_civil_parish_path(freecen2_civil_parish.id, type: 'index'), method: :get, class: 'btn   btn--small'
    else
      'No'
    end
  end

  def civil_parish_index_link(chapman_code, year)
    link_to "#{year}", freecen2_civil_parishes_chapman_year_index_path(chapman_code: "#{chapman_code}", year: "#{year}"), method: :get, class: 'btn   btn--small'
  end
end
