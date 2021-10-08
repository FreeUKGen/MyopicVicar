# -*- coding: utf-8 -*-
class CreateSearchRecordsFreecen2

  class << self
    def process(place, freecen2_place)
      searches = freecen2_place.search_records.count
      p freecen2_place.search_record_ids.count
      p searches
      if searches.zero?
        place.search_records.no_timeout.each do |record|
          freecen2_place.search_records << record
        end
      end
      dwellings = freecen2_place.freecen_dwellings.count
      p dwellings
      p  freecen2_place.freecen_dwelling_ids.count
      if dwellings.zero?
        place.freecen_dwellings.no_timeout.each do |dwelling|
          freecen2_place.freecen_dwellings << dwelling
        end
      end
      if searches.zero? || dwellings.zero?
        freecen2_place.save
        p freecen2_place
        p freecen2_place.search_record_ids.count
        p freecen2_place.search_records.count
        p freecen2_place.freecen_dwelling_ids.count
        p freecen2_place.freecen_dwellings.count
      end
    end
  end
end
