class Freecen2PlaceCache
  require 'freecen_constants'
  include Mongoid::Document
  field :chapman_code, type: String
  field :places_json, type: String

  index({ chapman_code: 1 }, { name: "chapman_code" })

  def self.refresh(county)
    Freecen2PlaceCache.where(chapman_code: county).destroy_all
    # the js library expects a certain format
    county_response = {}
    places = Freecen2Place.chapman_code(county).data_present.not_disabled.all.order_by(place_name: -1)
    places.each do |place|
      cen_years_with_data = ''
      Freecen::CENSUS_YEARS_ARRAY.each do |yy|
        if !place.cen_data_years.nil? && place.cen_data_years.include?(yy)
          if cen_years_with_data == ''
            cen_years_with_data += " #{yy}"
          else
            cen_years_with_data += ", #{yy}"
          end
        end
      end
      county_response[place.id] = "#{place.place_name} (#{cen_years_with_data})"
    end
    county_response = county_response.sort_by { |_, v| v }
    county_response = county_response.to_h

    cache = Freecen2PlaceCache.new(chapman_code: county, places_json: county_response.to_json)
    cache.save!
  end

  def self.refresh_all(county = '')
    if county == ''
      ChapmanCode.values.each do |chapman_code|
        refresh(chapman_code)
      end
    else
      refresh(county)
    end
  end

  def self.refresh_cache(place)
    cache = Freecen2PlaceCache.find_by(chapman_code: place.chapman_code)
    Freecen2PlaceCache.refresh(place.chapman_code) if cache.blank? || !cache.places_json.include?(place.place_name)
  end

  def self.check_and_refresh_if_absent
    num = Freecen2Place.collection.update_many({ data_present: true }, '$set' => { data_present: false, cen_data_years: [] })
    p num
    file_count = 0
    p 'starting csv'
    FreecenCsvFile.where(incorporated: true).each do |file|
      file_count += 1
      p file_count
      update_place = false
      freecen2_place = file.freecen2_place
      if freecen2_place.blank?
        p "Freecen2_place is missing for #{file.inspect}"
      else
        p freecen2_place
        unless freecen2_place.data_present
          update_place = true
        end
        cen_years = freecen2_place.cen_data_years
        unless cen_years.include?(file.year)

          cen_years << file.year
          p  cen_years
          update_place = true
        end
        p 'about to save'
        freecen2_place.update_attributes(data_present: true, cen_data_years: cen_years.sort) if update_place
        p 'place saved'
      end

      p freecen2_place
    end
    p 'finished csv'
    p 'starting vld'
    Freecen1VldFile.no_timeout.each do |file|
      file_count += 1
      p file_count
      update_place = false
      p file.id
      freecen2_place = file.freecen2_place
      p freecen2_place
      if freecen2_place.blank?
        p "Freecen2_place is missing for #{file.inspect}"
      else
        unless freecen2_place.data_present
          p 'need to set dataprent'
          update_place = true
          p 'set data present'
        end
        p freecen2_place.cen_data_years
        cen_years = freecen2_place.cen_data_years
        unless cen_years.include?(file.full_year)
          cen_years << file.full_year
          p cen_years
          update_place = true
        end
        p 'about to save'
        freecen2_place.update_attributes(data_present: true, cen_data_years: cen_years.sort) if update_place
        p 'place saved'
      end
      p freecen2_place
    end
    refresh_all
  end
end
