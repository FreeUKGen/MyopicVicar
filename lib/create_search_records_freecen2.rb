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

    def setup(fileid, number, message_file)
      message_file.puts "File number #{number} is blank" if fileid.blank?
      return [true, nil, nil] if fileid.blank?

      file = Freecen1VldFile.find_by(_id: fileid)
      return [true, nil, nil] if file.blank?

      message_file.puts "Number #{number} at #{Time.now} for file #{file.id}"
      freecen_piece = file.freecen_piece
      place = freecen_piece.place
      freecen2_piece = freecen_piece.freecen2_piece
      p "Missing Freecen2 piece for #{freecen_piece.inspect}" if freecen2_piece.blank?
      message_file.puts "Missing Freecen2 piece for #{freecen_piece.inspect}" if freecen2_piece.blank?
      return [true, nil, nil] if freecen2_piece.blank?

      freecen2_district = freecen2_piece.freecen2_district
      freecen2_place = freecen2_piece.freecen2_place
      freecen2_piece.freecen1_vld_files = [file] unless freecen2_piece.freecen1_vld_files.include?(file)
      freecen2_district.freecen1_vld_files = [file] unless freecen2_district.freecen1_vld_files.include?(file)
      freecen2_place.freecen1_vld_files = [file] unless freecen2_district.freecen1_vld_files.include?(file) || freecen2_place.blank?
      freecen2_piece.save unless freecen2_piece.freecen1_vld_files.include?(file)
      freecen2_district.save unless freecen2_district.freecen1_vld_files.include?(file)
      freecen2_place.save unless freecen2_piece.freecen1_vld_files.include?(file) || freecen2_place.blank?
      message_file.puts "Missing Freecen2 place for #{freecen_piece.inspect}" if freecen2_place.blank?
      return [true, place, freecen2_place] if freecen2_place.blank?

      if freecen2_place.data_present == false
        freecen2_place.data_present = true
        place_save_needed = true
      end
      unless freecen2_place.cen_data_years.include?(freecen_piece.year)
        freecen2_place.cen_data_years << freecen_piece.year
        place_save_needed = true
      end
      freecen2_place.save! if place_save_needed

      if freecen_piece.status == 'Online'
        freecen2_piece.update_attributes(status: 'Online', status_date: file._id.generation_time.to_datetime.in_time_zone('London'))
      end
      [false, place, freecen2_place]
    end
  end
end
