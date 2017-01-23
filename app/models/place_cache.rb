class PlaceCache
  include Mongoid::Document
  field :chapman_code, type: String
  field :places_json, type: String

  def self.refresh(county)
    PlaceCache.where(:chapman_code => county).destroy_all
    # the js library expects a certain format
    county_response = {"" => []}
    places = Place.chapman_code(county).not_disabled.all.order_by( place_name: 1)
    places.no_timeout.each do |place|
      if place.churches.exists? && place.search_records.exists?
        county_response[place.id] = "#{place.place_name} (#{ChapmanCode::name_from_code(place.chapman_code)})"
      end
    end
    cache = PlaceCache.new
    cache.update_attributes({ :chapman_code => county, :places_json => county_response.to_json})
    cache.save!
  end

  def self.refresh_all(county = '')
    if county == ''
      ChapmanCode::values.each do |chapman_code|
        refresh(chapman_code)
      end
    else
      refresh(county)
    end
  end

  def self.refresh_cache(place)
    cache = PlaceCache.where(:chapman_code => place.chapman_code).first
    PlaceCache.refresh(place.chapman_code) if cache.blank? || !cache.places_json.include?(place.place_name)
  end

end
