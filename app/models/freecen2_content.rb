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

  field :records, type: Hash # [chapman_code] [district_name] [place_name]

  index({ interval_end: -1})

  class << self

    def calculate(time = Time.now.utc)

      last_midnight = Time.utc(time.year, time.month, time.day)
      previous_midnight = Time.utc(time.year, time.month, time.day) - 30*24.hours
      p "Between #{previous_midnight} and #{last_midnight}"
      # find the existing record if it exists
      stat = Freecen2Content.find_by(interval_end: last_midnight)
      stat = Freecen2Content.new if stat.blank?
      # populate it
      stat.interval_end = last_midnight
      stat.year = time.year
      stat.month = time.month
      stat.day = time.day
      start = Time.now.utc

      # County

      records = Freecen2Content.setup_records(records, 'total')

      # Overall Totals

      fc2_totals_pieces, fc2_totals_pieces_online = Freecen2Piece.before_year_totals(last_midnight)
      fc2_added_pieces_online = Freecen2Piece.between_dates_year_totals(previous_midnight, last_midnight)

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
      @total_districts_cnt = 0
      @total_places_cnt = 0

      ChapmanCode.merge_counties.each do |county|

        # Testing -  if county == "SOM" || county == "LND" || county == "KEN"

        p "Starting to process County: #{county}"

        chaps += 1

        fc2_totals_pieces, fc2_totals_pieces_online = Freecen2Piece.before_county_year_totals(county, last_midnight)
        fc2_added_pieces_online = Freecen2Piece.between_dates_county_year_totals(county, previous_midnight, last_midnight)

        county_pieces_total = 0

        Freecen::CENSUS_YEARS_ARRAY.each do |year|
          county_pieces_total += fc2_totals_pieces[year]
        end

        if county_pieces_total > 0

          records = Freecen2Content.add_records_county(records, county)
          records[:total][:counties] <<  ChapmanCode.name_from_code(county)

          Freecen::CENSUS_YEARS_ARRAY.each do |year|
            records[county][year] = {}
            records[county][year][:pieces] = fc2_totals_pieces[year] # fc2_pieces are all the pieces so no need to add fc1_pieces
            records[county][:total][:pieces] += records[county][year][:pieces]
            records[county][year][:pieces_online] = fc2_totals_pieces_online[year]
            records[county][:total][:pieces_online] += records[county][year][:pieces_online]
            records[county][year][:added_pieces_online] = fc2_added_pieces_online[year]
            records[county][:total][:added_pieces_online] += records[county][year][:added_pieces_online]
          end # year

          # District totals

          cnty_districts = Freecen2Piece.distinct_districts(county)

          if cnty_districts.count > 0

            cnty_districts.each do |this_district|

              @total_districts_cnt += 1

              key_district = Freecen2Content.get_district_key(this_district)

              records = Freecen2Content.add_records_district(records, county, key_district)
              records[county][:total][:districts] << this_district

              fc2_totals_pieces, fc2_totals_pieces_online = Freecen2Piece.before_district_year_totals(county, this_district, last_midnight)
              fc2_added_pieces_online  = Freecen2Piece.between_dates_district_year_totals(county, this_district, previous_midnight, last_midnight)

              Freecen::CENSUS_YEARS_ARRAY.each do |year|

                district_rec = Freecen2District.find_by(chapman_code: county,name: this_district, year: year)
                if district_rec.present?
                  @district_id = district_rec._id
                else
                  @district_id = ""
                end

                records[county][key_district][year] = {}
                records[county][key_district][year][:district_id] = @district_id
                records[county][key_district][year][:pieces] = fc2_totals_pieces[year] # fc2_pieces are all the pieces so no need to add fc1_pieces
                records[county][key_district][:total][:pieces] += records[county][key_district][year][:pieces]
                records[county][key_district][year][:pieces_online] = fc2_totals_pieces_online[year]
                records[county][key_district][:total][:pieces_online] += records[county][key_district][year][:pieces_online]
                records[county][key_district][year][:added_pieces_online] = fc2_added_pieces_online[year]
                records[county][key_district][:total][:added_pieces_online] += records[county][key_district][year][:added_pieces_online]
              end # year

              # place totals

              if records[county][key_district][:total][:pieces] > 0

                district_places = Freecen2Piece.distinct_places(county, this_district)

                if district_places.count > 0

                  district_places.each do |this_place|

                    @total_places_cnt += 1

                    place_rec = Freecen2Place.find_by(chapman_code: county,place_name: this_place)
                    if place_rec.present?
                      @place_id = place_rec._id
                    else
                      @place_id = ""
                    end

                    key_place = Freecen2Content.get_place_key(this_place)

                    place_rec = Freecen2Place.find_by(chapman_code:county, place_name: this_place)

                    records = Freecen2Content.add_records_place(records, county, key_district, key_place)

                    records[county][key_district][:total][:places] << this_place
                    records[county][key_district][key_place][:total][:place_id] = @place_id  #No year(s) recorded for places

                    fc2_totals_pieces, fc2_totals_pieces_online = Freecen2Piece.before_place_year_totals(county, this_district, place_rec.id, last_midnight)
                    fc2_added_pieces_online  = Freecen2Piece.between_dates_place_year_totals(county, this_district, place_rec.id, previous_midnight, last_midnight)

                    Freecen::CENSUS_YEARS_ARRAY.each do |year|
                      records[county][key_district][key_place][year] = {}
                      records[county][key_district][key_place][year][:pieces] = fc2_totals_pieces[year] # fc2_pieces are all the pieces so no need to add fc1_pieces
                      records[county][key_district][key_place][:total][:pieces] += records[county][key_district][key_place][year][:pieces]
                      records[county][key_district][key_place][year][:pieces_online] = fc2_totals_pieces_online[year]
                      records[county][key_district][key_place][:total][:pieces_online] += records[county][key_district][key_place][year][:pieces_online]
                      records[county][key_district][key_place][year][:added_pieces_online] = fc2_added_pieces_online[year]
                      records[county][key_district][key_place][:total][:added_pieces_online] += records[county][key_district][key_place][year][:added_pieces_online]
                    end # year

                  end # place

                else
                  p "************ District (#{this_district}) has no places"
                end

              end

            end # district

          else
            county_name = ChapmanCode.name_from_code(county)
            p "************ (#{county}) - #{county_name} - County has no districts"
          end # districts count if > 0
        else
          county_name = ChapmanCode.name_from_code(county)
          p "************ (#{county}) - #{county_name} - County has no pieces"
        end

      end # county

      # testing - end

      p 'finished gathering latest data'
      p "counties = #{chaps}"
      p "districts = #{@total_districts_cnt}"
      p "places = #{@total_places_cnt}"

      stat.records = records
      stat.save

      remove_older_records(last_midnight)
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
      records[field][:total][:districts] = []
      records[field][:total][:pieces] = 0
      records[field][:total][:pieces_online] = 0
      records[field][:total][:added_pieces_online] = 0
      return records
    end

    def add_records_district(records, county, field)
      records[county][field] = {}
      records[county][field][:total] = {}
      records[county][field][:total][:places] = []
      records[county][field][:total][:pieces] = 0
      records[county][field][:total][:pieces_online] = 0
      records[county][field][:total][:added_pieces_online] = 0
      return records
    end

    def add_records_place(records, county, district, field)
      records[county][district][field] = {}
      records[county][district][field][:total] = {}
      records[county][district][field][:total][:pieces] = 0
      records[county][district][field][:total][:pieces_online] = 0
      records[county][district][field][:total][:added_pieces_online] = 0

      return records
    end

    def remove_older_records(latest)
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

    def get_district_key(district)
      # Full stops cannot be used in Hash keys - E.G. St. Quivox
      key_district = district.gsub(/\./,"*")
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

    def unique_names_place(place_id)
      first_names = SortedSet.new
      last_names = SortedSet.new
      rec_cnt = SearchRecord.where(freecen2_place_id: place_id).count
      if rec_cnt > 0
        search_records = SearchRecord.where(freecen2_place_id: place_id)
      end
      if search_records.present?
        search_records.each do |search_rec|
          search_rec.search_names.each do |name|
            first_names << name.first_name.upcase
            last_names << name.last_name.upcase
          end
        end
      end
      return first_names, last_names
    end

  end # self

end # class
