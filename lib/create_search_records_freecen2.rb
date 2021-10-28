# -*- coding: utf-8 -*-
class CreateSearchRecordsFreecen2

  class << self
    def process(file_id, freecen2_place)
      file = Freecen1VldFile.find_by(_id: file_id)
      p file.freecen_dwellings.count
      records = 0
      file.freecen_dwellings.no_timeout.each do |dwelling|
        freecen2_place.freecen_dwellings << dwelling
        dwelling.freecen_individuals.no_timeout.each do |individual|
          freecen2_place.search_records << individual.search_record
          records += 1
        end
      end
      p records
      freecen2_place.save
      p freecen2_place
      p freecen2_place.freecen_dwellings.count
      p freecen2_place.search_records.count
    end

    def setup(fileid, number, message_file)
      message_file.puts "File number #{number} is blank" if fileid.blank?
      return [true, nil, nil] if fileid.blank?

      file = Freecen1VldFile.find_by(_id: fileid)
      return [true, nil, nil] if file.blank?

      message_file.puts "Number #{number} at #{Time.now} for file #{file.id}"
      p "Number #{number} at #{Time.now} for file #{file.id}"
      freecen_piece = file.freecen_piece
      place = freecen_piece.place
      freecen2_piece = freecen_piece.freecen2_piece
      p "Missing Freecen2 piece for #{freecen_piece.inspect}" if freecen2_piece.blank?
      message_file.puts "Missing Freecen2 piece for #{freecen_piece.id} " if freecen2_piece.blank?
      return [true, nil, nil] if freecen2_piece.blank?

      freecen2_district = freecen2_piece.freecen2_district
      freecen2_place = freecen2_piece.freecen2_place
      p "Missing Freecen2 place for #{freecen_piece.id} with name #{freecen_piece.district_name} in #{freecen_piece.chapman_code}" if freecen2_place.blank?
      message_file.puts "Missing Freecen2 place for #{freecen_piece.id} with name #{freecen_piece.district_name} in #{freecen_piece.chapman_code}" if freecen2_place.blank?
      return [true, place, freecen2_place] if freecen2_place.blank?

      freecen2_piece.freecen1_vld_files << file unless freecen2_piece.freecen1_vld_files.include?(file)
      freecen2_district.freecen1_vld_files << file unless freecen2_district.freecen1_vld_files.include?(file)
      freecen2_place.freecen1_vld_files << file unless freecen2_place.freecen1_vld_files.include?(file)
      freecen2_piece.save unless freecen2_piece.freecen1_vld_files.include?(file)
      freecen2_district.save unless freecen2_district.freecen1_vld_files.include?(file)
      freecen2_place.save unless freecen2_place.freecen1_vld_files.include?(file)

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
