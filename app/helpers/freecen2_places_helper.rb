module Freecen2PlacesHelper
  def alternate(place)
    field = ''
    place.alternate_freecen2_place_names.each do |place_name|
      field += place_name.alternate_name
      field += ', '
    end
    field
  end
end
