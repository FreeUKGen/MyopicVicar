class PlaceCache
  include Mongoid::Document
  attr_accessible :chapman_code, :places_json


  def self.refresh(county)
    PlaceCache.where(:chapman_code => county).destroy_all
    # the js library expects a certain format
    county_response = {"" => []}
    places = Place.includes(:churches).where(:chapman_code => county).asc(:place_name)
    places.each do |place|
      if place.churches.count > 0
        county_response[place.id] = "#{place.place_name} (#{ChapmanCode::name_from_code(place.chapman_code)})"
      end
    end
    PlaceCache.create!({ :chapman_code => county, :places_json => county_response.to_json})
  end


  def self.refresh_all
    destroy_all

    ChapmanCode::values.each do |chapman_code|
      refresh(chapman_code)
    end

  end
end
