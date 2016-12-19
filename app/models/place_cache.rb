class PlaceCache
  include Mongoid::Document
  field :chapman_code, type: String
  field :places_json, type: String

  def self.refresh(county)
    PlaceCache.where(:chapman_code => county).destroy_all
    # the js library expects a certain format
    county_response = {"" => []}
    p "started #{county}"
    places = Place.chapman_code(county).not_disabled.all
    number = places.length
    p "places selected #{number}"
    n = 0
    number = 0
    places.no_timeout.each do |place|
      n = n + 1
      number = number + 1
      if n == 100
        n = 0
        p "#{number}"
      end
      if place.churches.count > 0 && place.records.to_i > 0
        county_response[place.id] = "#{place.place_name} (#{ChapmanCode::name_from_code(place.chapman_code)})"
      end
    end
    p "cache write"
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
