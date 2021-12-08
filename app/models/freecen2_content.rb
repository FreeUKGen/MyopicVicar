class Freecen2Content
  require 'chapman_code'
  require 'userid_role'
  require 'register_type'
  require 'freecen_constants'
  include Mongoid::Document
  include Mongoid::Timestamps::Short
  field :interval_end, type: DateTime
  field :year, type: Integer
  field :month, type: Integer
  field :day, type: Integer

  #  Unique Names placeholders
  field :county_select, type: String
  field :place_select, type: String
  field :year_select, type: String
  field :county_selected, type: String

  field :records, type: Hash # [chapman_code] [place_name]
  field :new_records, type: Array

  index({ interval_end: -1})

  class << self

    def calculate(time = Time.now.utc) # AEV Testing + 24.hours

      # AEV Testing - update_all = true # AEV
      update_all = false

      last_midnight = Time.utc(time.year, time.month, time.day)
      previous_midnight = Time.utc(time.year, time.month, time.day) - 30*24.hours

      previous_stat_data = Freecen2Content.order(interval_end: :desc).first
      no_previous_data_present = false

      if previous_stat_data.present?
        if previous_stat_data.interval_end == last_midnight
          stat = previous_stat_data
        else
          stat = Freecen2Content.new
        end
      else
        no_previous_data_present = true
        stat = Freecen2Content.new
      end

      p "New Pieces Online = between #{previous_midnight} and #{last_midnight}"

      # populate it
      stat.interval_end = last_midnight
      stat.year = time.year
      stat.month = time.month
      stat.day = time.day
      start = Time.now.utc

      # County

      if no_previous_data_present
        records = Freecen2Content.setup_records(records, 'total')
        new_records = []
      else
        records = previous_stat_data.records
        if previous_stat_data.new_records.blank?
          new_records = []
        else
          new_records = previous_stat_data.new_records
        end
      end

      # Overall Totals

      fc2_totals_pieces, fc2_totals_pieces_online = Freecen2Piece.before_year_totals(last_midnight)
      fc2_added_pieces_online = Freecen2Piece.between_dates_year_totals(previous_midnight, last_midnight)

      records[:total][:total][:pieces] = 0
      records[:total][:total][:pieces_online] = 0
      records[:total][:total][:added_pieces_online] = 0

      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        records[:total][year] = {}
        records[:total][year][:pieces] = fc2_totals_pieces[year] # fc2_pieces are all the pieces so no need to add fc1_pieces
        records[:total][:total][:pieces] += records[:total][year][:pieces]
        records[:total][year][:pieces_online] = fc2_totals_pieces_online[year]
        records[:total][:total][:pieces_online] += records[:total][year][:pieces_online]
        records[:total][year][:added_pieces_online] = fc2_added_pieces_online[year]
        records[:total][:total][:added_pieces_online] += records[:total][year][:added_pieces_online]
      end

      # County totals

      chaps = 0
      total_places_cnt = 0
      counties_array = []

      ChapmanCode.merge_counties.each do |county|

        # AEV Testing -  if county == "SOM" || county == "LND" || county == "ESS"

        p "Processing County: #{county}"

        fc2_totals_pieces, fc2_totals_pieces_online, fc2_totals_records_online = Freecen2Piece.before_county_year_totals(county, last_midnight)
        fc2_added_pieces_online = Freecen2Piece.between_dates_county_year_totals(county, previous_midnight, last_midnight)

        county_pieces_total = 0
        county_total_records_online = 0

        Freecen::CENSUS_YEARS_ARRAY.each do |year|
          county_pieces_total += fc2_totals_pieces[year]
          county_total_records_online += fc2_totals_records_online[year]
        end

        county_name = ChapmanCode.name_from_code(county)
        new_county = false

        if county_pieces_total > 0
          if records[county].present?
            if update_all || county_total_records_online != records[county][:total][:records_online] || county_pieces_total != records[county][:total][:pieces]
              refresh_county = true
            else
              refresh_county = false
            end
          else
            new_county = true      # new county to be processed for first time
            refresh_county = true
          end
        end

        if refresh_county

          p "Collecting data for County: #{county}"
          chaps += 1

          # clear new_records enties for this county
          if new_records.size > 0
            updated_array = []
            new_records.each do |entry|
              updated_array << entry unless entry[0] == county_name
            end
            new_records = updated_array
          end

          if no_previous_data_present || new_county
            records = Freecen2Content.add_records_county(records, county)
          end
          counties_array <<  county_name

          records[county][:total][:pieces] = 0
          records[county][:total][:pieces_online] = 0
          records[county][:total][:records_online] = 0
          records[county][:total][:added_pieces_online] = 0

          Freecen::CENSUS_YEARS_ARRAY.each do |year|

            records[county][year] = {}
            records[county][year][:pieces] = fc2_totals_pieces[year] # fc2_pieces are all the pieces so no need to add fc1_pieces
            records[county][:total][:pieces] += records[county][year][:pieces]
            records[county][year][:pieces_online] = fc2_totals_pieces_online[year]
            records[county][:total][:pieces_online] += records[county][year][:pieces_online]
            records[county][year][:records_online] = fc2_totals_records_online[year]
            records[county][:total][:records_online] += records[county][year][:records_online]
            records[county][year][:added_pieces_online] = fc2_added_pieces_online[year]
            records[county][:total][:added_pieces_online] += records[county][year][:added_pieces_online]

          end # year

          # place totals

          places = Freecen2Place.where(chapman_code: county, disabled: "false").sort
          places_array = []

          if places.count > 0

            places.each do |this_place|

              if this_place.freecen2_pieces.present? || SearchRecord.where(freecen2_place_id: this_place._id).present?

                total_places_cnt += 1

                key_place = Freecen2Content.get_place_key(this_place.place_name)

                if no_previous_data_present or records[county][key_place].blank?
                  records = Freecen2Content.add_records_place(records, county, key_place)
                end

                places_array << this_place.place_name
                records[county][key_place][:total][:place_id] = this_place._id

                fc2_totals_pieces, fc2_totals_pieces_online, fc2_totals_records_online, fc2_piece_ids = Freecen2Piece.before_place_year_totals(county, this_place._id, last_midnight)
                fc2_added_pieces_online  = Freecen2Piece.between_dates_place_year_totals(county, this_place._id, previous_midnight, last_midnight)

                piece_ids_array = []
                records[county][key_place][:total][:piece_ids] = []
                records[county][key_place][:total][:pieces] = 0
                records[county][key_place][:total][:pieces_online] = 0
                records[county][key_place][:total][:records_online] = 0
                records[county][key_place][:total][:added_pieces_online] = 0

                Freecen::CENSUS_YEARS_ARRAY.each do |year|
                  records[county][key_place][year] = {}
                  records[county][key_place][year][:piece_ids] = []
                  records[county][key_place][year][:piece_ids] = fc2_piece_ids[year]
                  piece_ids_array.concat(fc2_piece_ids[year])
                  records[county][key_place][year][:pieces] = fc2_totals_pieces[year] # fc2_pieces are all the pieces so no need to add fc1_pieces
                  records[county][key_place][:total][:pieces] += records[county][key_place][year][:pieces]
                  records[county][key_place][year][:pieces_online] = fc2_totals_pieces_online[year]
                  records[county][key_place][:total][:pieces_online] += records[county][key_place][year][:pieces_online]
                  records[county][key_place][year][:records_online] = fc2_totals_records_online[year]
                  records[county][key_place][:total][:records_online] += records[county][key_place][year][:records_online]
                  records[county][key_place][year][:added_pieces_online] = fc2_added_pieces_online[year]
                  records[county][key_place][:total][:added_pieces_online] += records[county][key_place][year][:added_pieces_online]

                  if fc2_added_pieces_online[year] > 0
                    county_name = ChapmanCode.name_from_code(county)
                    new_records << [county_name, this_place.place_name, county, this_place._id, year]
                  end

                end # year

                places_array_sorted = places_array.sort
                records[county][:total][:places] = places_array_sorted
                records[county][key_place][:total][:piece_ids] = piece_ids_array

              end

            end # places


          else
            county_name = ChapmanCode.name_from_code(county)
            p "************ (#{county}) - #{county_name} - County has no places"
          end

        else
          if county_pieces_total > 0
            counties_array <<  ChapmanCode.name_from_code(county)
          else
            county_name = ChapmanCode.name_from_code(county)
            p "************ (#{county}) - #{county_name} - County has no pieces"

          end
        end

        counties_array_sorted = counties_array.sort
        records[:total][:counties] = counties_array_sorted

      end # county

      # AEV Testing - end

      p 'finished gathering latest data'
      p "counties updated = #{chaps}"
      p "places updated = #{total_places_cnt}"


      # adjust for 'new_records' that are no longer new (I.e. > 30 days old)
      # new_records - [0] = County name, [1] = Place name, [2] = chapman_code, [3] = fc2_PLACE_id, [4] = year

      if new_records.size > 0
        adjusted_array = []
        new_records.each do |entry|
          key_place = Freecen2Content.get_place_key(entry[1])
          chapman_code = entry[2]
          place_id = entry[3]
          year = entry[4]

          all_years_pieces_online = Freecen2Piece.between_dates_place_year_totals(chapman_code, place_id, previous_midnight, last_midnight)
          pieces_online_cnt  = all_years_pieces_online[year]
          diff = records[chapman_code][key_place][year][:added_pieces_online]  - pieces_online_cnt

          records[chapman_code][key_place][year][:added_pieces_online] += diff
          records[chapman_code][key_place][:total][:added_pieces_online] += diff
          records[chapman_code][year][:added_pieces_online] += diff
          records[chapman_code][:total][:added_pieces_online] += diff

          if records[chapman_code][key_place][year][:added_pieces_online] > 0
            adjusted_array << entry
          end
        end
        new_records = adjusted_array
      end

      stat.records = records
      stat.new_records = new_records.sort
      stat.save

      #remove_older_records(last_midnight) - not used AEV

      run_time = Time.now.utc - start

      p "#{run_time} secs"

    end # calc

    def setup_records(records, field)
      records = {}
      records[field.to_sym] = {}
      records[field.to_sym][:counties] = []
      records[field.to_sym][:total] = {}
      records[field.to_sym][:total][:pieces] = 0
      records[field.to_sym][:total][:pieces_online] = 0
      records[field.to_sym][:total][:added_pieces_online] = 0
      return records
    end

    def add_records_county(records, field)
      records[field] = {}
      records[field][:total] = {}
      records[field][:total][:places] = []
      records[field][:total][:pieces] = 0
      records[field][:total][:pieces_online] = 0
      records[field][:total][:records_online] = 0
      records[field][:total][:added_pieces_online] = 0
      return records
    end

    def add_records_place(records, county, field)
      records[county][field] = {}
      records[county][field][:total] = {}
      records[county][field][:total][:piece_ids] = []
      records[county][field][:total][:pieces] = 0
      records[county][field][:total][:pieces_online] = 0
      records[county][field][:total][:records_online] = 0
      records[county][field][:total][:added_pieces_online] = 0
      return records
    end

    def remove_older_records(latest)  # not used
      del_cnt = 0
      all_recs = Freecen2Content.where().all
      all_recs.each do |rec|
        if rec.interval_end < latest
          rec.destroy
          del_cnt += 1
        end
      end
      p "#{del_cnt} older record(s) deleted"
    end

    def get_place_key(place)
      # Full stops cannot be used in Hash keys - E.G. St. Bees
      key_place = place.gsub(/\./,"*")
    end

    def letterize(names)
      new_list = {}
      remainder = names
      ("A".."Z").each do |letter|
        new_list[letter] = select_elements_starting_with(names, letter)
        remainder -= new_list[letter]
      end
      [new_list, remainder]
    end

    def select_elements_starting_with(arr, letter)
      arr.select { |str| str.start_with?(letter) }
    end

  end # self

end # class
