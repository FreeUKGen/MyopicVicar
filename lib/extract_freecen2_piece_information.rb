class ExtractFreecen2PieceInformation
  require 'chapman_code'

  COUNTY_ADJUSMENTS = {
    'LONDON' => 'London (City)',
    'DEVONSHIRE' => 'Devon',
    'YORKSHIRE - WEST RIDING' => 'Yorkshire, West Riding',
    'YORKSHIRE - EAST RIDING' => 'Yorkshire, East Riding',
    'YORKSHIRE - NORTH RIDING' => 'Yorkshire, North Riding',
    'GLAMORGANSHIRE' => 'Glamorgan',
    'CARNARVONSHIRE' => 'Caernarfonshire',
    'ISLE OF MAN' => 'Isle of Man',
    'GUERNSEY AND ADJACENT ISLANDS' => 'Guernsey',
    'London' => 'London (City)',
    'Kent extra metropolitan' => 'Kent',
    'Middlesex extra metropolitan' => 'Middlesex',
    'Glamorganshire' => 'Glamorgan',
    'Breconshire' => 'Brecknockshire',
    'Caernarvonshire' => 'Caernarfonshire',
    'Anglesea' => 'Anglesey',
    'Isle of man' => 'Isle of Man',
    'Royal navy ships' => 'Royal Navy Ships',
    'LONDON - MIDDLESEX' => 'London (City)',
    'LONDON - SURREY' => 'London (City)',
    'LONDON - KENT' => 'London (City)',
    'ROYAL NAVY AT SEA AND IN PORTS ABROAD' => 'Royal Navy Ships',
    'London - Middlesex' => 'London (City)',
    'London - Surrey' => 'London (City)',
    'London - Kent' => 'London (City)',
    'Royal Navy at sea and in ports abroad' => 'Royal Navy Ships',
    'Devonshire' => 'Devon',
    'Carnarvonshire' => 'Caernarfonshire',
    'Guernsey and adjacent Islands' => 'Guernsey',
    'Guernsey and adjacent islands' => 'Guernsey',
    'Isle of Man' => 'Isle of Man',
    'Islands in the British seas' => 'Channel Islands',
    'Lincolnshire: Parts of Holland' => 'Lincolnshire',
    'Lincolnshire: Parts of Kesteven' => 'Lincolnshire',
    'Lincolnshire: Parts of Lindsey' => 'Lincolnshire',
    'Brecon' => 'Brecknockshire',
    'Cardigan' => 'Cardiganshire',
    'Camarthen' => 'Carmarthenshire',
    'Carnarvon' => 'Caernarfonshire',
    'Denbigh' => 'Denbighshire',
    'Flint' => 'Flintshire',
    'Merioneth' => 'Merionethshire',
    'Montgomery' => 'Montgomeryshire',
    'Pembroke' => 'Pembrokeshire',
    'Radnor' => 'Radnorshire',
    'Dorsetshire' => 'Dorset',
    'Somersetshire' => 'Somerset',
    'Rutlandshire' => 'Rutland',
    'Yorkshire, East Riding (with York)' => 'Yorkshire, East Riding',
    'Royal Navy' => 'Royal Navy Ships',
    'Miscellaneous unidentified pages and fragments' => 'Royal Navy Ships',
    'Shipping at sea and in ports abroad' => 'England and Wales Shipping',
    'British Ships in home ports' => 'England and Wales Shipping',
  }
  class << self
    def process(limit, file)
      file_of_parms = Rails.root.join('test_data/new_parms', "#{file}")
      xml = File.open(file_of_parms)
      census = Hash.from_xml(xml)
      census_year = census["parms"]["census"]
      year = census_year['year']
      county = census_year['county']
      file_for_warning_messages = Rails.root.join('log', "#{year}_extract_freecen2_parms.txt")
      FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
      @output_file = File.new(file_for_warning_messages, 'w')
      file_for_missing_place_names = Rails.root.join('log', "#{year}_missing_place_names.txt")
      FileUtils.mkdir_p(File.dirname(file_for_missing_place_names))
      missing_places = File.new(file_for_missing_place_names, 'w')
      start = Time.now
      @last_piece = nil
      @adjustments = 0
      @missing_place_names = []
      @output_file.puts "#{year} #{file} #{start}"
      if county.respond_to?('each_pair')
        # process single county
        chapman_code = ExtractFreecen2PieceInformation.extract_chapman_code(county['name'])
        crash if chapman_code.blank?
        ExtractFreecen2PieceInformation.process_county(county, year)
      else
        # process array of counties
        county.each do |individual_county|
          chapman_code = ExtractFreecen2PieceInformation.extract_chapman_code(individual_county['name'])
          crash if chapman_code.blank?
        end
        county.each do |individual_county|
          p "Commencing #{individual_county['name']}"
          ExtractFreecen2PieceInformation.process_county(individual_county, year)
        end
      end
      missing_places.puts  @missing_place_names
      @output_file.puts Time.now
      elapse = Time.now - start
      @output_file.puts elapse
      @output_file.close
      p "#{@adjustments} file adjustments made"
      p 'finished'
    end

    def process_county(county, year)
      tnaid = county['tnaid']
      county_name = county['name']
      @output_file.puts county_name
      chapman_code = ExtractFreecen2PieceInformation.extract_chapman_code(county_name)
      @output_file.puts chapman_code
      active_county = County.find_by(chapman_code: chapman_code)
      value = county['district']
      if value.present?
        if value.respond_to?('each_pair')
          if year == '1851' && county_name == "Islands in the British seas"
            chapman_code = ExtractFreecen2PieceInformation.correct_chapman_code(value)
            active_county = County.find_by(chapman_code: chapman_code)
          end
          district_object = ExtractFreecen2PieceInformation.process_district(value, chapman_code, year)
          active_county.freecen2_districts << district_object
        else
          value.each do |district|
            if year == '1851' && county_name == "Islands in the British seas"
              chapman_code = ExtractFreecen2PieceInformation.correct_chapman_code(district)
              active_county = County.find_by(chapman_code: chapman_code)
            end
            district_object = ExtractFreecen2PieceInformation.process_district(district, chapman_code, year)
            active_county.freecen2_districts << district_object
          end
        end
      else
        @output_file.puts " No districts for pieces for county #{county} #{year} "
      end
      result = active_county.save
      unless result
        @output_file.puts "County save failed #{county_name} #{chapman_code}"
        @output_file.puts county.errors.full_messages
        crash
      end
    end

    def process_district(district, chapman_code, year)
      district_tnaid = district['tnaid']
      district_name = district['name']
      district_code = district['code']
      district_type = district['type']
      district_year = district['year']
      district_year = year if district_year.blank?
      if district_name.blank?
        @output_file.puts "Blank name for district #{district_tnaid} #{district_code}"
        return nil
      end
      place_id = ExtractFreecen2PieceInformation.locate_district_place(chapman_code, district_name, district_name, 'District')
      @district_object = Freecen2District.new(name: district_name, code: district_code, tnaid: district_tnaid, chapman_code: chapman_code,
                                              year: district_year, freecen2_place_id: place_id, type: district_type)
      result = @district_object.save
      unless result
        @output_file.puts "district #{district_tnaid} #{district_code}"
        @output_file.puts @district_object.errors.full_messages
        crash
      end
      if district_year == '1841'
        piece_object = ExtractFreecen2PieceInformation.process_subdistrict(district, district_year, @district_object, district)
        @district_object.freecen2_pieces << piece_object
      else
        value = district['subdistrict']
        if value.present?
          if value.respond_to?('each_pair')
            piece_object = ExtractFreecen2PieceInformation.process_subdistrict(value, district_year, @district_object, district)
            @district_object.freecen2_pieces << piece_object
          else
            value.each do |subdistrict|
              piece_object = ExtractFreecen2PieceInformation.process_subdistrict(subdistrict, district_year, @district_object, district)
              @district_object.freecen2_pieces << piece_object
            end
          end
        else
          if district['parish'].present?
            piece_object = ExtractFreecen2PieceInformation.process_subdistrict(district, district_year, @district_object, district)
            @district_object.freecen2_pieces << piece_object
          else
            @output_file.puts " No pieces or parishes for district #{district_name} #{district_tnaid} "
          end
        end
      end
      result = @district_object.save
      unless result
        @output_file.puts "district #{district_tnaid} #{district_code}"
        @output_file.puts @district_object.errors.full_messages
        crash
      end
      @district_object
    end

    def process_subdistrict(subdistrict, year, district_object, district)
      subdistrict_tnaid = subdistrict['tnaid']
      subdistrict_name = subdistrict['name']
      subdistrict_code = subdistrict['code']
      subdistrict_piece = subdistrict['piece']
      subdistrict_year = subdistrict['year']
      subdistrict_prenote = subdistrict['prenote']
      subdistrict_year = year if subdistrict_year.blank?
      subdistrict_tnaid = district['tnaid'] if subdistrict_tnaid.blank?
      if @last_piece.blank?
        @last_piece = subdistrict_piece
        @last_increment = 0
        @last_tnaid = subdistrict_tnaid
      else
        if @last_piece == subdistrict_piece
          @last_increment += 1
          @adjustments += 1
          subdistrict_piece += 'A' if @last_increment == 1
          subdistrict_piece += 'B' if @last_increment == 2
          subdistrict_piece += 'C' if @last_increment == 3
          subdistrict_piece += 'D' if @last_increment == 4
          subdistrict_piece += 'E' if @last_increment == 5
          subdistrict_piece += 'F' if @last_increment == 6
          subdistrict_piece += 'G' if @last_increment == 7
          subdistrict_piece += 'H' if @last_increment == 8
          subdistrict_piece += 'I' if @last_increment == 9
          subdistrict_piece += 'J' if @last_increment == 10
          subdistrict_piece += 'K' if @last_increment == 11
          subdistrict_piece += 'L' if @last_increment == 12
          subdistrict_tnaid =  @last_tnaid
        else
          @last_piece = subdistrict_piece
          @last_increment = 0
          @last_tnaid = subdistrict_tnaid
        end
      end

      subdistrict_name = district['name'] if subdistrict_name.blank? && district['name'].present?
      subdistrict_piece = district['piece'] if subdistrict_piece.blank? && district['piece'].present?
      subdistrict_piece = ExtractFreecen2PieceInformation.convert_piece_number(subdistrict_piece)
      if subdistrict_name.blank?
        @output_file.puts "Blank name for piece #{subdistrict_tnaid} #{subdistrict_piece} #{subdistrict_code}"
        return nil
      end
      place_id = ExtractFreecen2PieceInformation.locate_subdistrict_place(district_object, subdistrict_name, district_object.freecen2_place_id, 'Piece')
      @subdistrict_object = Freecen2Piece.new(name: subdistrict_name, code: subdistrict_code, tnaid: subdistrict_tnaid,
                                              number: subdistrict_piece, year: subdistrict_year, freecen2_place_id: place_id,
                                              freecen2_district_id: district_object.id, prenote: subdistrict_prenote,
                                              chapman_code: district_object.chapman_code)
      result = @subdistrict_object.save
      unless result
        @output_file.puts "piece #{subdistrict_tnaid} #{subdistrict_piece} #{subdistrict_code}"
        @output_file.puts @subdistrict_object.errors.full_messages
        crash
      end
      value = subdistrict['parish']
      if value.present?
        if value.respond_to?('each_pair')
          parish_object = ExtractFreecen2PieceInformation.process_parish(value, @subdistrict_object, district_object.chapman_code)
          @subdistrict_object.freecen2_civil_parishes << parish_object
        else
          value.each do |parish|
            parish_object = ExtractFreecen2PieceInformation.process_parish(parish, @subdistrict_object, district_object.chapman_code)
            @subdistrict_object.freecen2_civil_parishes << parish_object
          end
        end
      else
        @output_file.puts " No parishes for district #{subdistrict_name} #{subdistrict_tnaid} "
      end
      result = @subdistrict_object.save
      unless result
        @output_file.puts "piece #{subdistrict_tnaid} #{subdistrict_piece} #{subdistrict_code}"
        @output_file.puts @subdistrict_object.errors.full_messages
        crash
      end
      civil_parish_names = @subdistrict_object.add_update_civil_parish_list
      @subdistrict_object.update(civil_parish_names: civil_parish_names)
      @subdistrict_object
    end

    def process_parish(parish, subdistrict_object, chapman_code)
      parish_name = parish['name']
      parish_note = parish['note']
      parish_prenote = parish['prenote']
      place_id = ExtractFreecen2PieceInformation.locate_civil_place(chapman_code, parish_name, subdistrict_object, 'Civil Parish')
      @parish_object = Freecen2CivilParish.new(name: parish_name, note: parish_note, freecen2_piece_id: subdistrict_object.id, prenote: parish_prenote,
                                               freecen2_place_id: place_id, year: subdistrict_object.year, chapman_code: chapman_code)
      result = @parish_object.save
      unless result
        @output_file.puts "Parish #{parish_name} "
        @output_file.puts @parish_object.errors.full_messages
        crash
      end
      value = parish['hamlet']
      if value.respond_to?('each_pair')
        hamlet_object = ExtractFreecen2PieceInformation.process_hamlet(value)
        @parish_object.freecen2_hamlets << hamlet_object
      elsif value.present?
        value.each do |hamlet|
          hamlet_object = ExtractFreecen2PieceInformation.process_hamlet(hamlet)
          @parish_object.freecen2_hamlets << hamlet_object
        end
      end
      value = parish['township']
      if value.respond_to?('each_pair')
        township_object = ExtractFreecen2PieceInformation.process_township(value)
        @parish_object.freecen2_townships << township_object if township_object.present?
      elsif value.present?
        value.each do |township|
          township_object = ExtractFreecen2PieceInformation.process_township(township)
          @parish_object.freecen2_townships << township_object if township_object.present?
          @output_file.puts "Nil array for #{parish_name}#{parish_note}" if township_object.blank?
        end
      end
      value = parish['ward']
      if value.respond_to?('each_pair')
        ward_object = ExtractFreecen2PieceInformation.process_ward(value)
        @parish_object.freecen2_wards << ward_object if ward_object.present?
      elsif value.present?
        value.each do |ward|
          ward_object = ExtractFreecen2PieceInformation.process_township(ward)
          @parish_object.freecen2_wards << ward_object if ward_object.present?
          @output_file.puts "Nil array for #{parish_name}#{parish_note}" if ward_object.blank?
        end
      end
      result = @parish_object.save
      unless result
        @output_file.puts "Parish #{parish_name} "
        @output_file.puts @parish_object.errors.full_messages
        crash
      end
      @parish_object
    end

    def process_hamlet(hamlet)
      return nil if hamlet.blank?

      hamlet_name = hamlet['name']
      hamlet_note = hamlet['note']
      hamlet_prenote = hamlet['prenote']
      hamlet_object = Freecen2Hamlet.new(name: hamlet_name, note: hamlet_note, prenote: hamlet_prenote)
      hamlet_object
    end

    def process_township(township)
      return nil if township.blank?

      township_name = township['name']
      township_note = township['note']
      township_prenote = township['prenote']
      township_object = Freecen2Township.new(name: township_name, note: township_note, prenote: township_prenote)
      township_object
    end

    def process_ward(ward)
      return nil if ward.blank?

      ward_name = ward['name']
      ward_note = ward['note']
      ward_prenote = ward['prenote']
      ward_object = Freecen2Ward.new(name: ward_name, note: ward_note, prenote: ward_prenote)
      ward_object
    end

    def extract_chapman_code(county_name)
      valid_county = ChapmanCode.has_key?(county_name.titleize) if county_name.present?
      unless valid_county
        if COUNTY_ADJUSMENTS.include?(county_name) && ChapmanCode.has_key?(COUNTY_ADJUSMENTS[county_name])
          county_name = COUNTY_ADJUSMENTS[county_name]
          chapman_code = ChapmanCode.merge_countries[county_name]
          return chapman_code
        else
          @output_file.puts 'invalid county name'
          @output_file.puts county_name
          return nil
        end
      end
      chapman_code = ChapmanCode.merge_countries[county_name.titleize]
      chapman_code
    end

    def correct_chapman_code(district)
      county_name = district['name']
      chapman_code = ExtractFreecen2PieceInformation.extract_chapman_code(county_name)
      @output_file.puts "County name changed to #{county_name}"
      chapman_code
    end

    def convert_piece_number(piece)
      piece_parts = piece.split('/')
      piece_parts[0] = piece_parts[0].gsub(/\s+/, '')
      piece = piece_parts[0] + '_' + piece_parts[1]
      piece
    end

    def locate_district_place(chapman_code, name, place_previous, type)
      myname = Freecen2Place.standard_place(name)
      place = Freecen2Place.find_by(chapman_code: chapman_code, standard_place_name: myname)
      if place.present?
        place_id = place.id
      elsif place.blank?
        place = Freecen2Place.find_by(:chapman_code => chapman_code, "alternate_freecen2_place_names.standard_alternate_name" => myname)
        if place.present?
          place_id = place.id
        else
          place = Freecen2Place.find_by(chapman_code: chapman_code, original_standard_name: myname)
          if place.present?
            place_id = place.id
          else
            @missing_place_names << "#{myname} a #{type} in | #{chapman_code}"
          end
        end
      end
      place_id
    end

    def locate_subdistrict_place(district, name, place_previous, type)
      myname = Freecen2Place.standard_place(name)
      place = Freecen2Place.find_by(chapman_code: district.chapman_code, standard_place_name: myname)
      if place.present?
        place_id = place.id
      elsif place.blank?
        place = Freecen2Place.find_by(:chapman_code => district.chapman_code, "alternate_freecen2_place_names.standard_alternate_name" => myname)
        if place.present?
          place_id = place.id
        else
          place = Freecen2Place.find_by(chapman_code: district.chapman_code, original_standard_name: myname)
          if place.present?
            place_id = place.id
          else
            if district.freecen2_place_id.present?
              place_id = district.freecen2_place_id
            else
              @missing_place_names << "#{myname} a #{type} in | #{district.chapman_code}| district #{district.name} "
            end
          end
        end
      end
      place_id
    end

    def locate_civil_place(chapman_code, name, piece, type)
      myname = Freecen2Place.standard_place(name)
      district_name = piece.freecen2_district.name
      piece_name = piece.name
      place = Freecen2Place.find_by(chapman_code: chapman_code, standard_place_name: myname)
      if place.present?
        place_id = place.id
      elsif place.blank?
        place = Freecen2Place.find_by(:chapman_code => chapman_code, "alternate_freecen2_place_names.standard_alternate_name" => myname)
        if place.present?
          place_id = place.id
        else
          place = Freecen2Place.find_by(chapman_code: chapman_code, original_standard_name: myname)
          if place.present?
            place_id = place.id
          else
            if piece.freecen2_place_id.present?
              place_id = piece.freecen2_place_id
            else
              @missing_place_names << "#{myname} a #{type} in | #{chapman_code}| district #{district_name} | sub district (piece) #{piece_name} "
            end
          end
        end
      end
      place_id
    end
  end
end
