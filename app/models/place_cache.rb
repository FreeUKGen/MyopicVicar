class PlaceCache
  include Mongoid::Document
  attr_accessible :chapman_code, :places_json


  def self.refresh(inspect_churches, county)
    PlaceCache.where(:chapman_code => county).destroy_all
    # the js library expects a certain format
    county_response = {"" => []}
    
    if(inspect_churches)
      places = Place.where(:chapman_code => county).asc(:place_name)
      places.each do |place|
        if place.churches.exists? && place.search_records.exists?
          county_response[place.id] = "#{place.place_name} (#{ChapmanCode::name_from_code(place.chapman_code)})"
        end
      end
    else
      places = Place.where(:chapman_code => county).asc(:place_name)
      places.each do |place|
        if place.data_present
          cen_years_with_data = ""
          [1841,1851,1861,1871,1881,1891].each do |yy|
            if !place.cen_data_years.nil? && place.cen_data_years.include?(yy)
              if(""==cen_years_with_data)
                cen_years_with_data += " #{yy}"
              else
                cen_years_with_data += ",'#{yy-1800}"
              end
            end
          end
          if MyopicVicar::Application.config.template_set == 'freereg'
            county_response[place.id] = "#{place.place_name} (#{ChapmanCode::name_from_code(place.chapman_code)})"
          elsif MyopicVicar::Application.config.template_set == 'freecen'
            county_response[place.id] = "#{place.place_name} (#{place.chapman_code}#{cen_years_with_data})"
          end
        end
      end
    end
    PlaceCache.create!({ :chapman_code => county, :places_json => county_response.to_json})
  end


  def self.refresh_all(inspect_churches = true)
    destroy_all
    ChapmanCode::values.each do |chapman_code|
      refresh(inspect_churches, chapman_code)
    end

  end
end
