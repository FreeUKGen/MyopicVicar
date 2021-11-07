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
    p 'starting'
    FreecenCsvFile.where(incorporated: true).each do |file|
      next if file.freecen2_place.present?

      if file.freecen2_piece.present?
        if file.freecen2_piece.freecen2_place.present?
          file.freecen2_place = file.freecen2_piece.freecen2_place
          file.save
        else
          p "piece for file #{file.inspect} has no place"
        end
      else
        p "csv file #{file.inspect} has no piece"
      end
    end
    ChapmanCode.values.sort.each do |chapman_code|
      p chapman_code
      p Freecen2Place.chapman_code(chapman_code).not_disabled.length
      check = 0
      Freecen2Place.chapman_code(chapman_code).not_disabled.all.no_timeout.order_by(place_name: 1).each do |freecen2_place|
        check += 1

        freecen2_place.update_attributes(data_present: false, cen_data_years: []) unless freecen2_place.data_present == false
        freecen2_place_save_needed = false
        if freecen2_place.freecen1_vld_files.present?
          freecen2_place.freecen1_vld_files.each do |vld_file|
            unless freecen2_place.data_present == true
              freecen2_place.data_present = true
              freecen2_place_save_needed = true
            end
            unless freecen2_place.cen_data_years.include?(vld_file.full_year)
              freecen2_place.cen_data_years << vld_file.full_year
              freecen2_place_save_needed = true
            end
          end
        end
        if freecen2_place.freecen_csv_files.present?
          freecen2_place.freecen_csv_files.each do |csv_file|
            unless freecen2_place.data_present == true
              freecen2_place.data_present = true
              freecen2_place_save_needed = true
            end
            unless freecen2_place.cen_data_years.include?(csv_file.year)
              freecen2_place.cen_data_years << csv_file.year
              freecen2_place_save_needed = true
            end
          end
        end
        freecen2_place.cen_data_years = freecen2_place.cen_data_years.sort if freecen2_place_save_needed
        freecen2_place.save if freecen2_place_save_needed
        p "#{check}, #{freecen2_place.place_name} updated " if freecen2_place_save_needed
      end
      refresh(chapman_code)
    end
  end
end
