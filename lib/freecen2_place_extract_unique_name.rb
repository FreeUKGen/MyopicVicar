class Freecen2PlaceExtractUniqueName
  class << self
    def process(days)
      file_for_messages = 'log/freecen2_place_extract_unique_names_report.log'
      message_file = File.new(file_for_messages, 'w')
      days = days.to_i
      p "Updating Freecen2 Place unique names"
      message_file.puts 'Updating Freecen2 Place unique names'
      num = 0
      time_start = Time.now
      p "time_start #{time_start}"

      if days == 0
        place_ids = Freecen2Place.data_present.map{|p| p.id.to_s }
      else
        previous_time = Time.utc(time_start.year, time_start.month, time_start.day) - days*24.hours
        p "previous_time #{previous_time}"
        #place_ids = SearchRecord.between(u_at: previous_time..time_start).no_timeout.map{|p| p.freecen2_place_id.to_s }.uniq

        fc2_piece_ids = Freecen2Piece.between(status_date: previous_time..time_start).pluck(:id)
      end

      fc2_piece_ids.each do |piece_id|

        place_ids = SearchRecord.where(freecen2_piece_id: piece_id).map{|p| p.freecen2_place_id.to_s }.uniq

        place_ids.each do |place_id|

          unique_forenames = {}
          unique_surnames = {}
          years_with_names_cnt = 0

          Freecen::CENSUS_YEARS_ARRAY.each do |year|

            distinct_forenames = []
            distinct_surnames = []
            distinct_forenames, distinct_surnames = unique_names_place(place_id, year)
            unless  distinct_forenames.empty? && distinct_surnames.empty?
              unique_forenames[year] = distinct_forenames
              unique_surnames[year] = distinct_surnames
              years_with_names_cnt += 1
            end

          end # end years

          if years_with_names_cnt > 0

            place_unique_name = Freecen2PlaceUniqueName.find_by(freecen2_place_id: place_id)
            if place_unique_name.present?
              place_unique_name.update_attributes(unique_forenames: unique_forenames, unique_surnames: unique_surnames)
            else
              place_unique_name = Freecen2PlaceUniqueName.new(freecen2_place_id: place_id, unique_forenames: unique_forenames, unique_surnames: unique_surnames)
              place_unique_name.save
            end

            place = Freecen2Place.find_by(_id: place_id)
            p "Populated names for: #{place_id}, #{place.chapman_code}, #{place.place_name}"
            message_file.puts "Populated names for: #{place_id}, #{place.chapman_code}, #{place.place_name}"
          end

          num += 1

        end # end places

      end # pieces

      time_elapsed = Time.now - time_start
      p "Finished processing #{num} places in #{time_elapsed} secs"
      message_file.puts "Finished processing #{num} freecen2_places in #{time_elapsed} secs"
    end

    def unique_names_place(place_id, year)
      first_names = SortedSet.new
      last_names = SortedSet.new
      rec_cnt = SearchRecord.where(freecen2_place_id: place_id, record_type: year).count
      if rec_cnt > 0
        search_records = SearchRecord.where(freecen2_place_id: place_id, record_type: year)
      end
      if search_records.present?
        search_records.each do |search_rec|
          search_rec.search_names.each do |name|
            first_names << name.first_name.upcase unless name.first_name.blank?
            last_names << name.last_name.upcase unless name.last_name.blank?
          end
        end
      end
      return first_names, last_names
    end
  end
end
