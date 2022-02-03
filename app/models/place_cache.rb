class PlaceCache
  require 'freecen_constants'
  include Mongoid::Document
  field :chapman_code, type: String
  field :places_json, type: String

  index({ chapman_code: 1 }, { name: "chapman_code" })

  def self.refresh(county)
    PlaceCache.where(chapman_code: county).destroy_all
    # the js library expects a certain format
    county_response = {}
    appname = MyopicVicar::Application.config.template_set
    case appname
    when 'freereg'
      places = Place.chapman_code(county).data_present.not_disabled.all.order_by(place_name: 1)
      places.each do |place|
        county_response[place.id] = "#{place.place_name} (#{ChapmanCode.name_from_code(place.chapman_code)})"
      end
    when 'freecen'
      # do not inspect churches for freecen
      # places = Place.where(:chapman_code => county).asc(:place_name)
      places = Freecen2Place.chapman_code(county).data_present.not_disabled.all.order_by(place_name: -1)
      places.each do |place|
        cen_years_with_data = ''
        Freecen::CENSUS_YEARS_ARRAY.each do |yy|
          if !place.cen_data_years.nil? && place.cen_data_years.include?(yy)
            if cen_years_with_data == ''
              cen_years_with_data += " #{yy}"
            else
              cen_years_with_data += ",'#{yy}"
            end
          end
        end
        county_response[place.id] = "#{place.place_name} (#{place.chapman_code}#{cen_years_with_data})"
      end
      values = county_response.values
      places = Place.chapman_code(county).data_present.not_disabled.all.order_by(place_name: -1)
      places.each do |place|
        cen_years_with_data = ''
        Freecen::CENSUS_YEARS_ARRAY.each do |yy|
          if !place.cen_data_years.nil? && place.cen_data_years.include?(yy)
            if cen_years_with_data == ''
              cen_years_with_data += " #{yy}"
            else
              cen_years_with_data += ",'#{yy}"
            end
          end
        end
        content = "#{place.place_name} (#{place.chapman_code}#{cen_years_with_data})"
        county_response[place.id] = content unless values.include?(content)
      end
      county_response = county_response.sort_by { |_, v| v }
      county_response = county_response.to_h
    end
    cache = PlaceCache.new(chapman_code: county, places_json: county_response.to_json)
    cache.save!
  end

  def self.refresh_all(county = '')
    if county == ''
      ChapmanCode.values.uniq.each do |chapman_code|
        refresh(chapman_code)
      end
    else
      refresh(county)
    end
  end

  def self.refresh_cache(place)
    cache = PlaceCache.find_by(chapman_code: place.chapman_code)
    PlaceCache.refresh(place.chapman_code) if cache.blank? || !cache.places_json.include?(place.place_name)
  end

  def self.check_and_refresh_if_absent
    ChapmanCode.values.each do |chapman_code|
      if Place.chapman_code(chapman_code).data_present.not_disabled.present? && PlaceCache.find_by(chapman_code: chapman_code).places_json.length <= 7
        refresh(chapman_code)
      end
    end
  end
end
