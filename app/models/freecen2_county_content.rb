class Freecen2CountyContent

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
  field :county, type: String  # added AEV
  field :records, type: Hash # [place_name]  - was [chapman_code] [place_name]
  field :new_records, type: Array

  index({ interval_end: -1, county: 1 })

  class << self

    def calculate(time, mode)
      if mode == 'FULL'
        update_all = true
      else
        update_all = false
      end

      last_midnight = Time.utc(time.year, time.month, time.day)
      previous_midnight = Time.utc(time.year, time.month, time.day) - 30 * 24.hours
      start = Time.now.utc

      p "New Pieces Online = between #{previous_midnight} and #{last_midnight}"


      # County

      # look for record for county existing

      # County totals

      chaps = 0
      total_places_cnt = 0
      counties_array = []

      ChapmanCode.merge_counties.each do |county|


        # AEV Testing - if county == "SOM" || county == "LND" || county == "ESS"

        p "Processing County: #{county}"

        exclude_counties = %w[ENG OVB OVF OUC OTH SCT UNK]

        next if exclude_counties.include?(county)


        #  ##############  AEV look for esisting country record

        # look for record for county existing already


        if update_all
          stat = Freecen2CountyContent.find_by(interval_end: last_midnight, county: county)
          stat = Freecen2CountyContent.new if stat.blank?
        else
          previous_stat_data = Freecen2CountyContent.where(county: county).order_by(interval_end: :desc).first
          no_previous_data_present = false

          if previous_stat_data.present?
            if previous_stat_data.interval_end == last_midnight
              stat = previous_stat_data
            else
              stat = Freecen2CountyContent.new
            end
          else
            no_previous_data_present = true
            stat = Freecen2CountyContent.new
          end
        end

        if no_previous_data_present || update_all
          records = Freecen2CountyContent.setup_records_county(records)
          new_records = []
        else
          records = previous_stat_data.records
          if previous_stat_data.new_records.blank?
            new_records = []
          else
            new_records = previous_stat_data.new_records
          end
        end


        fc2_totals_pieces, fc2_totals_pieces_online, fc2_totals_records_online, fc2_piece_ids = Freecen2Piece.before_county_year_totals(county, last_midnight)
        fc2_added_pieces_online, fc2_added_records_online = Freecen2Piece.between_dates_county_year_totals(county, previous_midnight, last_midnight)

        county_pieces_total = 0
        county_added_records_online = 0

        Freecen::CENSUS_YEARS_ARRAY.each do |year|
          county_pieces_total += fc2_totals_pieces[year]
          county_added_records_online += fc2_added_records_online[year]
        end

        county_name = ChapmanCode.name_from_code(county)
        new_county = false

        if update_all
          refresh_county = true
        else
          if county_pieces_total > 0
            if previous_stat_data
              if update_all || county_needs_updating(records, county, county_pieces_total, county_added_records_online)
                refresh_county = true
              else
                refresh_county = false
              end
            else
              new_county = true # new county to be processed for first time
              refresh_county = true
            end
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

          if no_previous_data_present || new_county || update_all
            records = Freecen2CountyContent.setup_records_county(records)
          end
          counties_array << county_name

          records[:total][:pieces] = 0
          records[:total][:pieces_online] = 0
          records[:total][:records_online] = 0
          records[:total][:added_pieces_online] = 0
          records[:total][:added_records_online] = 0
          records[:total][:piece_ids] = []

          Freecen::CENSUS_YEARS_ARRAY.each do |year|

            records[year] = {}
            records[year][:piece_ids] = fc2_piece_ids[year]
            records[:total][:piece_ids].concat(fc2_piece_ids[year])
            records[year][:pieces] = fc2_totals_pieces[year] # fc2_pieces are all the pieces so no need to add fc1_pieces
            records[:total][:pieces] += records[year][:pieces]
            records[year][:pieces_online] = fc2_totals_pieces_online[year]
            records[:total][:pieces_online] += records[year][:pieces_online]
            records[year][:records_online] = fc2_totals_records_online[year]
            records[:total][:records_online] += records[year][:records_online]
            records[year][:added_records_online] = fc2_added_records_online[year]
            records[:total][:added_records_online] += records[year][:added_records_online]
            records[year][:added_pieces_online] = fc2_added_pieces_online[year]
            records[:total][:added_pieces_online] += records[year][:added_pieces_online]

          end
          # end year

          # place totals

          places = Freecen2Place.where(chapman_code: county, disabled: 'false').sort
          places_array = []

          if places.count.positive?

            places.each do |this_place|

              if this_place.freecen2_pieces.present? || SearchRecord.where(freecen2_place_id: this_place._id).present?

                total_places_cnt += 1

                key_place = Freecen2CountyContent.get_place_key(this_place.place_name)

                if no_previous_data_present || records[key_place].blank? || update_all
                  records = Freecen2CountyContent.add_records_place(records, key_place)
                end

                records[key_place][:total][:place_id] = this_place._id

                fc2_totals_pieces, fc2_totals_pieces_online, fc2_totals_records_online, fc2_piece_ids = Freecen2Piece.before_place_year_totals(this_place._id, last_midnight)
                fc2_added_pieces_online, fc2_added_records_online = Freecen2Piece.between_dates_place_year_totals(this_place._id, previous_midnight, last_midnight)

                place_dates = '=('
                piece_ids_array = []
                records[key_place][:total][:piece_ids] = []
                records[key_place][:total][:pieces] = 0
                records[key_place][:total][:pieces_online] = 0
                records[key_place][:total][:records_online] = 0
                records[key_place][:total][:added_pieces_online] = 0
                records[key_place][:total][:added_records_online] = 0

                Freecen::CENSUS_YEARS_ARRAY.each do |year|
                  records[key_place][year] = {}
                  records[key_place][year][:piece_ids] = []
                  records[key_place][year][:piece_ids] = fc2_piece_ids[year]
                  piece_ids_array.concat(fc2_piece_ids[year])
                  records[key_place][year][:pieces] = fc2_totals_pieces[year] # fc2_pieces are all the pieces so no need to add fc1_pieces
                  records[key_place][:total][:pieces] += records[key_place][year][:pieces]
                  records[key_place][year][:pieces_online] = fc2_totals_pieces_online[year]
                  records[key_place][:total][:pieces_online] += records[key_place][year][:pieces_online]
                  records[key_place][year][:records_online] = fc2_totals_records_online[year]
                  records[key_place][:total][:records_online] += records[key_place][year][:records_online]
                  records[key_place][year][:added_records_online] = fc2_added_records_online[year]
                  records[key_place][:total][:added_records_online] += records[key_place][year][:added_records_online]
                  records[key_place][year][:added_pieces_online] = fc2_added_pieces_online[year]
                  records[key_place][:total][:added_pieces_online] += records[key_place][year][:added_pieces_online]

                  if fc2_added_records_online[year] > 0
                    county_name = ChapmanCode.name_from_code(county)
                    new_records << [county_name, this_place.place_name, county, this_place._id, year, fc2_added_records_online[year]]
                  end

                  if fc2_totals_pieces_online[year].positive?
                    place_dates += year + ', '
                  end

                end
                # end year


                if place_dates.length > 2
                  place_dates.delete_suffix!(', ')
                  place_dates += ')'
                  places_array << this_place.place_name + place_dates
                else
                  places_array << this_place.place_name
                end

                places_array_sorted = places_array.sort
                records[:total][:places] = places_array_sorted
                records[key_place][:total][:piece_ids] = piece_ids_array

              end

            end
            # end places

          else
            county_name = ChapmanCode.name_from_code(county)
            p "************ (#{county}) - #{county_name} - County has no places"
          end

        else
          if county_pieces_total > 0
            counties_array << ChapmanCode.name_from_code(county)
          else
            county_name = ChapmanCode.name_from_code(county)
            p "************ (#{county}) - #{county_name} - County has no pieces"

          end

        end


        if !update_all && new_records.size.positive?
          # nb overall totals are always re-calculated so no need to adjust those
          #
          # adjust for 'new_records' that are no longer new (I.e. > 30 days old)
          # new_records - [0] = County name, [1] = Place name, [2] = chapman_code, [3] = fc2_PLACE_id, [4] = year, [5] = added records - OLD AEV
          # new_records - [0] = County name, [1] = Place name, [2] = chapman_code, [3] = fc2_PLACE_id, [4] = year, [5] = added records
          #
          p 'Adjusting Recently Added'   ######   AEV Do this at end of each county

          adjusted_array = []
          new_records.each do |entry|

            key_place = Freecen2CountyContent.get_place_key(entry[1])
            chapman_code = entry[2]   #   not used ?? as county records now  AEV
            place_id = entry[3]
            year = entry[4]
            added_recs = entry[5]

            place_added_pieces_online, place_added_records = Freecen2Piece.between_dates_place_year_totals(place_id, previous_midnight, last_midnight)
            place_pieces_online_cnt =  place_added_pieces_online[year]
            diff_place_pieces = records[key_place][year][:added_pieces_online] - place_pieces_online_cnt
            records[key_place][year][:added_pieces_online] -= diff_place_pieces
            records[key_place][:total][:added_pieces_online] -= diff_place_pieces
            place_recs_cnt =  place_added_records[year]
            diff_place_recs = records[key_place][year][:added_records_online] - place_recs_cnt
            records[key_place][year][:added_records_online] -= diff_place_recs
            records[key_place][:total][:added_records_online] -= diff_place_recs

            county_added_pieces_online, county_added_records = Freecen2Piece.between_dates_county_year_totals(chapman_code, previous_midnight, last_midnight)
            county_pieces_online_cnt = county_added_pieces_online[year]
            diff_county_pieces = records[year][:added_pieces_online] - county_pieces_online_cnt
            records[year][:added_pieces_online] -= diff_county_pieces
            records[:total][:added_pieces_online] -= diff_county_pieces
            county_recs_cnt = county_added_records[year]
            diff_county_recs = records[year][:added_records_online] - county_recs_cnt
            records[year][:added_records_online] -= diff_county_recs
            records[:total][:added_records_online] -= diff_county_recs

            adjusted_array << entry if records[key_place][year][:added_pieces_online].positive? || records[key_place][year][:added_records_online].positive?

          end
          new_records = adjusted_array

        end


        stat.records = records
        stat.new_records = new_records.sort
        stat.county = county
        stat.interval_end = last_midnight
        stat.year = time.year
        stat.month = time.month
        stat.day = time.day
        stat.save

        p "AEV01 county_name = #{county_name}"


      end

      # end county


      # AEV Testing -end


      # Overall totals

      if update_all
        stat = Freecen2CountyContent.find_by(interval_end: last_midnight, county: 'ALL')
        stat = Freecen2CountyContent.new if stat.blank?
      else
        previous_stat_data = Freecen2CountyContent.where(county: 'ALL').order_by(interval_end: :desc).first
        no_previous_data_present = false

        if previous_stat_data.present?
          if previous_stat_data.interval_end == last_midnight
            stat = previous_stat_data
          else
            stat = Freecen2CountyContent.new
          end
        else
          no_previous_data_present = true
          stat = Freecen2CountyContent.new
        end
      end

      if no_previous_data_present || update_all
        records = Freecen2CountyContent.setup_records_all(records)
        new_records = []
      else
        records = previous_stat_data.records
        if previous_stat_data.new_records.blank?
          new_records = []
        else
          new_records = previous_stat_data.new_records
        end
      end

      stat.county = 'ALL'
      stat.interval_end = last_midnight
      stat.year = time.year
      stat.month = time.month
      stat.day = time.day


      fc2_totals_pieces, fc2_totals_pieces_online = Freecen2Piece.before_year_totals(last_midnight)
      fc2_added_pieces_online = Freecen2Piece.between_dates_year_totals(previous_midnight, last_midnight)

      records[:total][:pieces] = 0
      records[:total][:pieces_online] = 0
      records[:total][:added_pieces_online] = 0

      Freecen::CENSUS_YEARS_ARRAY.each do |year|

        records[year] = {}
        records[year][:pieces] = fc2_totals_pieces[year] # fc2_pieces are all the pieces so no need to add fc1_pieces
        records[:total][:pieces] += records[year][:pieces]
        records[year][:pieces_online] = fc2_totals_pieces_online[year]
        records[:total][:pieces_online] += records[year][:pieces_online]
        records[year][:added_pieces_online] = fc2_added_pieces_online[year]
        records[:total][:added_pieces_online] += records[year][:added_pieces_online]

      end

      p "AEV04 counties_array #{counties_array}"

      counties_array_sorted = counties_array.sort
      records[:total][:counties] = counties_array_sorted

      stat.records = records
      stat.new_records = new_records.sort
      stat.save

      # AEV end of overall totals section



      p 'Finished gathering latest data'
      p "Counties updated = #{chaps}"
      p "Places updated = #{total_places_cnt}"



      run_time = Time.now.utc - start

      p "#{run_time} secs"

    end

    # calc

    def setup_records_all(records)
      records = {}
      records[:total] = {}
      records[:total][:counties] = []
      records[:total][:piece_ids] = []
      records[:total][:places] = []
      records[:total][:pieces] = 0
      records[:total][:pieces_online] = 0
      records[:total][:records_online] = 0
      records[:total][:added_pieces_online] = 0
      records[:total][:added_records_online] = 0
      return records
    end

    def setup_records_county(records)
      records = {}
      records[:total] = {}
      records[:total][:piece_ids] = []
      records[:total][:places] = []
      records[:total][:pieces] = 0
      records[:total][:pieces_online] = 0
      records[:total][:records_online] = 0
      records[:total][:added_pieces_online] = 0
      records[:total][:added_records_online] = 0
      return records
    end

    def add_records_place(records, field)
      records[field] = {}
      records[field][:total] = {}
      records[field][:total][:piece_ids] = []
      records[field][:total][:pieces] = 0
      records[field][:total][:pieces_online] = 0
      records[field][:total][:records_online] = 0
      records[field][:total][:added_pieces_online] = 0
      records[field][:total][:added_records_online] = 0
      return records
    end

    def county_needs_updating(records, county, county_pieces_total, county_added_records_online)
      needs_update = false

      if county_added_records_online != records[:total][:added_records_online] || county_pieces_total != records[:total][:pieces]
        needs_update = true
      else
        county_places = records[:total][:places]
        county_places.each do |place|
          place_name = place.split('=')[0]
          if Freecen2Place.find_by(chapman_code: county, place_name: place_name).blank?
            needs_update = true
            break
          end
        end
      end
      return needs_update
    end

    def get_place_key(place)
      # Full stops cannot be used in Hash keys - E.G. St. Bees
      key_place = place.gsub(/\./,"*")
    end

    def letterize(names)
      new_list = {}
      remainder = names
      ('A'..'Z').each do |letter|
        new_list[letter] = select_elements_starting_with(names, letter)
        remainder -= new_list[letter]
      end
      [new_list, remainder]
    end

    def select_elements_starting_with(arr, letter)
      arr.select { |str| str.start_with?(letter) }
    end

  end
  # self

end
# class
