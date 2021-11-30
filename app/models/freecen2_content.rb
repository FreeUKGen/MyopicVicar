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

      new_records = []

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
      total_places_cnt = 0
      counties_array = []

      ChapmanCode.merge_counties.each do |county|

        # Testing -  if county == "SOM" || county == "LND" || county == "KEN"

        p "Starting to process County: #{county}"

        chaps += 1

        fc2_totals_pieces, fc2_totals_pieces_online, fc2_totals_records_online = Freecen2Piece.before_county_year_totals(county, last_midnight)
        fc2_added_pieces_online = Freecen2Piece.between_dates_county_year_totals(county, previous_midnight, last_midnight)

        county_pieces_total = 0

        Freecen::CENSUS_YEARS_ARRAY.each do |year|
          county_pieces_total += fc2_totals_pieces[year]
        end

        if county_pieces_total > 0

          records = Freecen2Content.add_records_county(records, county)
          counties_array <<  ChapmanCode.name_from_code(county)

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

              if this_place.freecen2_pieces.present?

                total_places_cnt += 1

                key_place = Freecen2Content.get_place_key(this_place.place_name)
                records = Freecen2Content.add_records_place(records, county, key_place)

                places_array << this_place.place_name
                records[county][key_place][:total][:place_id] = this_place._id

                fc2_totals_pieces, fc2_totals_pieces_online, fc2_totals_records_online = Freecen2Piece.before_place_year_totals(county, this_place._id, last_midnight)
                fc2_added_pieces_online  = Freecen2Piece.between_dates_place_year_totals(county, this_place._id, previous_midnight, last_midnight)


                Freecen::CENSUS_YEARS_ARRAY.each do |year|
                  records[county][key_place][year] = {}
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

              end

            end # places

          else
            county_name = ChapmanCode.name_from_code(county)
            p "************ (#{county}) - #{county_name} - County has no places"
          end

          counties_array_sorted = counties_array.sort
          records[:total][:counties] = counties_array_sorted

        else
          county_name = ChapmanCode.name_from_code(county)
          p "************ (#{county}) - #{county_name} - County has no pieces"
        end

      end # county

      # testing - end

      p 'finished gathering latest data'
      p "counties = #{chaps}"
      p "places = #{total_places_cnt}"

      stat.records = records
      stat.new_records = new_records.sort
      stat.save

      #remove_older_records(last_midnight)
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
      records[county][field][:total][:pieces] = 0
      records[county][field][:total][:pieces_online] = 0
      records[county][field][:total][:records_online] = 0
      records[county][field][:total][:added_pieces_online] = 0
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
