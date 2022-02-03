class Freecen2PlaceCache
  require 'freecen_constants'
  include Mongoid::Document
  field :chapman_code, type: String
  field :places_json, type: String

  index({ chapman_code: 1 }, { name: "chapman_code" })

  def self.refresh(county)
    p "refreshing #{county}"
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
      ChapmanCode.values.uniq.each do |chapman_code|
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
    file_count = 0
    p 'starting csv'
    FreecenCsvFile.where(incorporated: true).no_timeout.each do |file|
      file_count += 1
      p file_count
      p "#{file._id} #{file.chapman_code} #{file.file_name}"
      freecen2_place = file.freecen2_place
      p 'bypassing' if freecen2_place.present? && freecen2_place.u_at > 1.day.ago
      next if freecen2_place.present? && freecen2_place.u_at > 1.day.ago

      if freecen2_place.present?
        p " Place #{freecen2_place.place_name}"
        freecen2_place.update_data_present_after_csv_delete
      end
      piece = file.freecen2_piece
      p "Piece #{piece.number}"
      piece.freecen2_civil_parishes.no_timeout.each do |civil_parish|
        next if civil_parish.freecen_csv_entries.blank?

        freecen2_place = civil_parish.freecen2_place
        freecen2_place.update_data_present(piece)
        p "#{freecen2_place.place_name} updated"
        piece.save!
      end
    end
    p 'finished csv'
    p 'starting vld'
    Freecen1VldFile.no_timeout.each do |file|
      file_count += 1
      p file_count
      update_place = false
      freecen2_place = file.freecen2_place
      if freecen2_place.blank?
        p "(((((((((((((((((((((((((((((((((Freecen2_place is missing for #{file.inspect}"
      else
        update_place = true  unless freecen2_place.data_present
        cen_years = freecen2_place.cen_data_years
        unless cen_years.include?(file.full_year)
          cen_years << file.full_year
          update_place = true
        end
        freecen2_place.update_attributes(data_present: true, cen_data_years: cen_years.sort) if update_place
        p "#{freecen2_place.place_name} updated" if update_place
      end
    end
    refresh_all
  end
end
