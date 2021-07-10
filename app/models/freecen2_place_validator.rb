class Freecen2PlaceValidator
  def initialize(freecen2_place)
    @freecen2_place = freecen2_place
  end

  def validate_location
    if @freecen2_place.grid_reference.blank?
      if @freecen2_place.latitude.blank? || @freecen2_place.longitude.blank?
        @freecen2_place.errors.add(:grid_reference, "Either the grid reference or the lat/lon must be present")
      else
        @freecen2_place.errors.add(:latitude, "The latitude must be between -90 and 90") unless @freecen2_place.latitude.to_i > -90 && @freecen2_place.latitude.to_i < 90
        @freecen2_place.errors.add(:longitude, "The longitude must be between -180 and 180") unless @freecen2_place.longitude.to_i > -180 && @freecen2_place.longitude.to_i < 180
      end
    elsif @freecen2_place.grid_reference.is_gridref?
      my_location = @freecen2_place.grid_reference.to_latlng.to_a
      @freecen2_place.latitude = my_location[0]
      @freecen2_place.longitude = my_location[1]
    else
      @freecen2_place.errors.add(:grid_reference, "The grid reference is not correctly formatted")
    end
  end
end
