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

  field :records, type: Hash # [chapman_code] [district_name]

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

      fc1_totals_pieces, fc1_totals_pieces_online = FreecenPiece.before_year_totals(last_midnight)
      fc2_totals_pieces, fc2_totals_pieces_online = Freecen2Piece.before_year_totals(last_midnight)
      fc1_added_pieces_online, na_1, na_2, na_4 = Freecen1VldFile.between_dates_year_totals(previous_midnight, last_midnight)
      fc2_added_pieces_online = Freecen2Piece.between_dates_year_totals(previous_midnight, last_midnight)

      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        records[:total][year] = {}
        records[:total][year][:pieces] = fc2_totals_pieces[year] # fc2_pieces are all the pieces so no need to add fc1_pieces
        records[:total][:total][:pieces] += records[:total][year][:pieces]
        records[:total][year][:pieces_online] = fc1_totals_pieces_online[year] + fc2_totals_pieces_online[year]
        records[:total][:total][:pieces_online] += records[:total][year][:pieces_online]
        records[:total][year][:added_pieces_online] = fc1_added_pieces_online[year] + fc2_added_pieces_online[year]
        records[:total][:total][:added_pieces_online] += records[:total][year][:added_pieces_online]
      end

      # County totals

      chaps = 0
      @total_districts_cnt = 0

      ChapmanCode.merge_counties.each do |county|

        p "Starting to process County: #{county}"

        chaps += 1
        @district_cnt = 0

        records = Freecen2Content.add_records_county(records, county)

        fc1_totals_pieces, fc1_totals_pieces_online = FreecenPiece.before_county_year_totals(county, last_midnight)
        fc2_totals_pieces, fc2_totals_pieces_online = Freecen2Piece.before_county_year_totals(county, last_midnight)
        fc1_added_pieces_online, na_1, na_2, na_4  = Freecen1VldFile.between_dates_county_year_totals(county, previous_midnight, last_midnight)
        fc2_added_pieces_online = Freecen2Piece.between_dates_county_year_totals(county, previous_midnight, last_midnight)

        Freecen::CENSUS_YEARS_ARRAY.each do |year|
          records[county][year] = {}
          records[county][year][:pieces] = fc2_totals_pieces[year] # fc2_pieces are all the pieces so no need to add fc1_pieces
          records[county][:total][:pieces] += records[county][year][:pieces]
          records[county][year][:pieces_online] = fc1_totals_pieces_online[year] + fc2_totals_pieces_online[year]
          records[county][:total][:pieces_online] += records[county][year][:pieces_online]
          records[county][year][:added_pieces_online] = fc1_added_pieces_online[year] + fc2_added_pieces_online[year]
          records[county][:total][:added_pieces_online] += records[county][year][:added_pieces_online]
        end # year

        # District totals

        if records[county][:total][:pieces] > 0

          cnty_districts = Freecen2Piece.distinct_districts(county, last_midnight)

          if cnty_districts.count > 0

            cnty_districts.each do |this_district|

              @district_start = Time.now.utc

              @district_cnt += 1
              @total_districts_cnt += 1

              key_district = Freecen2Content.get_district_key(this_district)

              records = Freecen2Content.add_records_district(records, county, key_district)

              fc1_totals_pieces, fc1_totals_pieces_online = FreecenPiece.before_district_year_totals(county, this_district, last_midnight)
              fc1_added_pieces_online  = FreecenPiece.between_dates_district_year_totals(county, this_district, previous_midnight, last_midnight)
              fc2_totals_pieces, fc2_totals_pieces_online = Freecen2Piece.before_district_year_totals(county, this_district, last_midnight)
              fc2_added_pieces_online  = Freecen2Piece.between_dates_district_year_totals(county, this_district, previous_midnight, last_midnight)

              Freecen::CENSUS_YEARS_ARRAY.each do |year|
                records[county][key_district][year] = {}
                records[county][key_district][year][:pieces] = fc2_totals_pieces[year] # fc2_pieces are all the pieces so no need to add fc1_pieces
                records[county][key_district][:total][:pieces] += records[county][key_district][year][:pieces]
                records[county][key_district][year][:pieces_online] = fc1_totals_pieces_online[year] + fc2_totals_pieces_online[year]
                records[county][key_district][:total][:pieces_online] += records[county][key_district][year][:pieces_online]
                records[county][key_district][year][:added_pieces_online] = fc1_added_pieces_online[year] + fc2_added_pieces_online[year]
                records[county][key_district][:total][:added_pieces_online] += records[county][key_district][year][:added_pieces_online]
              end # year

            end # district


            processing_time = (Time.now.utc - @district_start).round(2)

            p "#{@district_cnt} districts processed in #{processing_time} secs"
          else
            county_name = ChapmanCode.name_from_code(county)
            p "************ (#{county}) - #{county_name} - County has no districts"
          end # districts count if > 0
        else
          county_name = ChapmanCode.name_from_code(county)
          p "************ (#{county}) - #{county_name} - County has no pieces"
        end

      end # county

      p 'finished'
      p "counties = #{chaps}"
      p "districts = #{@total_districts_cnt}"
      p Time.now.utc - start
      stat.records = records
      stat.save
    end # calc

    def setup_records(records, field)
      records = {}
      records[field.to_sym] = {}
      records[field.to_sym][:total] = {}
      records[field.to_sym][:total][:pieces] = 0
      records[field.to_sym][:total][:pieces_online] = 0
      records[field.to_sym][:total][:added_pieces_online] = 0
      return records
    end

    def add_records_county(records, field)
      records[field] = {}
      records[field][:total] = {}
      records[field][:total][:pieces] = 0
      records[field][:total][:pieces_online] = 0
      records[field][:total][:added_pieces_online] = 0
      return records
    end

    def add_records_district(records, county, field)
      records[county][field] = {}
      records[county][field][:total] = {}
      records[county][field][:total][:pieces] = 0
      records[county][field][:total][:pieces_online] = 0
      records[county][field][:total][:added_pieces_online] = 0
      return records
    end

    def get_district_key(district)
      # Full stops cannot be used in Hash keys - E.G. St. Quivox found in fc1 piece for AYR
      # ERROR => BSON::String::IllegalKey: 'St. Quivox' is an illegal key in MongoDB. Keys may not start with '$' or contain a '.'.
      key_district = district.gsub(/\./,"*")
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
