task :create_freecen2_parms_scotland, [:limit] => :environment do |t, args|

  require 'chapman_code'
  require 'extract_freecen2_piece_information'

  file_for_output = "#{Rails.root}/log/scotland_parms.txt"
  FileUtils.mkdir_p(File.dirname(file_for_output) )
  output_file = File.new(file_for_output, "w")


  # Print the time before start the process
  start_time = Time.now
  p "Starting at #{start_time}"
  lim = args.limit.to_i
  number = 0
  @missing_district_places = []
  @missing_civil_parish_places = []
  codes = ChapmanCode.remove_codes(ChapmanCode::CODES)
  codes = codes["Scotland"]
  codes.each_value do |chapman|
    p chapman
    Freecen::CENSUS_YEARS_ARRAY.each do |year|
      @district = ''
      @parish_name = ''
      FreecenPiece.where(year: year, chapman_code: chapman).order_by(piece_number: 1, parish_number: 1).no_timeout.each do |piece|
        number += 1
        break if number > lim

        p piece
        unless @district == piece.district_name
          p 'New district'
          @district = piece.district_name
          district_name = piece.district_name
          district_name = district_name.gsub(/&/, ' and ')
          p district_name
          place_id = ExtractFreecen2PieceInformation.locate_district_place(chapman, district_name, district_name, 'District')
          county_id = County.find_by(chapman_code: chapman).id if County.find_by(chapman_code: chapman).present?
          @missing_district_places << chapman + ':' + district_name if place_id.blank?

          @district_object = Freecen2District.new(name: district_name, chapman_code: chapman, year: year, freecen2_place_id: place_id,
                                                  county_id: county_id, tnaid: 'None')
          @district_object.vld_files << piece.freecen1_filename
          # p @district_object
          result = @district_object.save
          crash unless result

          piece2_number = Freecen2Piece.calculate_freecen2_piece_number(piece)
          @subdistrict_object = Freecen2Piece.new(name: district_name, number: piece2_number, year: year, freecen2_place_id: place_id, chapman_code: chapman,
                                                  freecen2_district_id: @district_object.id, film_number: piece.film_number,
                                                  suffix: piece.suffix, piece_number: piece.piece_number)
          @subdistrict_object.vld_files << piece.freecen1_filename
          # p @subdistrict_object
          result = @subdistrict_object.save
          crash unless result

          parish_name = piece.subplaces[0]['name']
          parish_name = parish_name.gsub(/&/, ' and ')
          p parish_name
          unless @parish_name == parish_name
            p 'new district and new parish'
            @parish_name = parish_name
            place_id = ExtractFreecen2PieceInformation.locate_civil_place(chapman, parish_name, @subdistrict_object, 'Civil Parish')

            @missing_civil_parish_places << parish_name if place_id.blank?
            @parish_object = Freecen2CivilParish.new(name: parish_name,  freecen2_piece_id: @subdistrict_object.id, number: piece.parish_number,
                                                     freecen2_place_id: place_id, year: year, chapman_code: chapman, suffix: piece.suffix)

            @parish_object.vld_files << piece.freecen1_filename
            result = @parish_object.save
            crash unless result
            civil_parish_names = @subdistrict_object.add_update_civil_parish_list
            @subdistrict_object.update(civil_parish_names: civil_parish_names)
            p @parish_object
            p civil_parish_names
          else
            p 'new district and same parish'
            @parish_object.vld_files << piece.freecen1_filename
            @parish_object.save
            p @parish_object
          end
        else
          parish_name = piece.subplaces[0]['name']
          parish_name = parish_name.gsub(/&/, ' and ')
          p 'same district'
          p @district
          p parish_name
          @district_object.vld_files << piece.freecen1_filename
          @subdistrict_object.vld_files << piece.freecen1_filename
          @district_object.save
          @subdistrict_object.save
          unless @parish_name == parish_name
            p 'same district and new parish'
            @parish_name = parish_name
            place_id = ExtractFreecen2PieceInformation.locate_civil_place(chapman, parish_name, @subdistrict_object, 'Civil Parish')

            @missing_civil_parish_places << chapman + ':' + parish_name if place_id.blank?
            @parish_object = Freecen2CivilParish.new(name: parish_name,  freecen2_piece_id: @subdistrict_object.id, number: piece.parish_number,
                                                     freecen2_place_id: place_id, year: year, chapman_code: chapman, suffix: piece.suffix)

            @parish_object.vld_files << piece.freecen1_filename
            result = @parish_object.save
            crash unless result
            civil_parish_names = @subdistrict_object.add_update_civil_parish_list
            @subdistrict_object.update(civil_parish_names: civil_parish_names)
            p @parish_object
            p civil_parish_names
          else
            p 'same district and parish'
            @parish_object.vld_files << piece.freecen1_filename
            @parish_object.save

          end
        end
      end
      break if number >= lim
    end
    break if number >= lim
  end


  p "Process finished"
  p 'Missing district names'
  p @missing_district_places
  running_time = Time.now - start_time
  p "Running time #{running_time}  for #{number - 1} pieces"
end
