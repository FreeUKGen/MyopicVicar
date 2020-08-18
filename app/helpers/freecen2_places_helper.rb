module Freecen2PlacesHelper
  def alternate(place)
    field = ''
    place.alternate_freecen2_place_names.each_with_index do |place_name, ind|
      field += ', ' if ind > 0
      field += place_name.alternate_name
    end
    field
  end
end
