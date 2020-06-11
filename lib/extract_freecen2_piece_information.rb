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
    'Royal Navy' => 'Royal Navy Ships'
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
      file_for_missing_place_names =  Rails.root.join('log', "#{year}_missing_place_names.txt")
      FileUtils.mkdir_p(File.dirname(file_for_missing_place_names))
      missing_places = File.new(file_for_missing_place_names, 'w')
      start = Time.now
      @output_file.puts start
      @missing_place_names = []
      @output_file.puts year
      p 'Commencing'
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
      @missing_place_names = @missing_place_names.uniq
      missing_places.puts  @missing_place_names
      @output_file.puts Time.now
      elapse = Time.now - start
      @output_file.puts elapse
      @output_file.close
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
          district_object = ExtractFreecen2PieceInformation.process_district(value, chapman_code)
          active_county.freecen2_districts << district_object
        else
          value.each do |district|
            district_object = ExtractFreecen2PieceInformation.process_district(district, chapman_code)
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

    def process_district(district, chapman_code)
      district_tnaid = district['tnaid']
      district_name = district['name']
      district_code = district['code']
      district_type = district['type']
      district_year = district['year']
      if district_name.blank?
        @output_file.puts "Blank name for district #{district_tnaid} #{district_code}"
        return nil
      end
      place = Place.find_by(place_name: district_name.titleize) if district_name.present?
      if place.blank?
        p "No place for district #{district_name}"
        @missing_place_names << district_name
        place_id = nil
      else
        place_id = place.id
      end
      district_object = Freecen2District.new(name: district_name, code: district_code, tnaid: district_tnaid, chapman_code: chapman_code,
                                             year: district_year, place_id: place_id, type: district_type)
      if district_year == '1841'
        piece_object = ExtractFreecen2PieceInformation.process_subdistrict(district, district_year, district_object)
        district_object.freecen2_pieces << piece_object
      else
        value = district['subdistrict']
        if value.present?
          if value.respond_to?('each_pair')
            piece_object = ExtractFreecen2PieceInformation.process_subdistrict(value, district_year, district_object)
            district_object.freecen2_pieces << piece_object
          else
            value.each do |subdistrict|
              piece_object = ExtractFreecen2PieceInformation.process_subdistrict(subdistrict, district_year, district_object)
              district_object.freecen2_pieces << piece_object
            end
          end
        else
          @output_file.puts " No pieces for district #{district_name} #{district_tnaid} "
        end
      end
      result = district_object.save
      unless result
        @output_file.puts "district #{district_tnaid} #{district_code}"
        @output_file.puts district_object.errors.full_messages
        crash
      end
      district_object
    end

    def process_subdistrict(subdistrict, year, district_object)
      subdistrict_tnaid = subdistrict['tnaid']
      subdistrict_name = subdistrict['name']
      subdistrict_code = subdistrict['code']
      subdistrict_piece = subdistrict['piece']
      subdistrict_year = subdistrict['year']
      subdistrict_year = year if year == '1851' || year == '1841'

      if subdistrict_name.blank?
        @output_file.puts "Blank name for piece #{subdistrict_tnaid} #{subdistrict_piece} #{subdistrict_code}"
        return nil
      end

      place = Place.find_by(place_name: subdistrict_name.titleize) if subdistrict_name.present?
      if place.blank?
        p "No place for piece #{subdistrict_name}"
        @missing_place_names << subdistrict_name
        place_id = nil
      else
        place_id = place.id
      end
      subdistrict_object = Freecen2Piece.new(name: subdistrict_name, code: subdistrict_code, tnaid: subdistrict_tnaid,
                                             number: subdistrict_piece, place_id: place_id, year: subdistrict_year, freecen2_district_id: district_object.id )

      value = subdistrict['parish']
      if value.present?
        if value.respond_to?('each_pair')
          parish_object = ExtractFreecen2PieceInformation.process_parish(value, subdistrict_object)
          subdistrict_object.freecen2_civil_parishes << parish_object
        else
          value.each do |parish|
            parish_object = ExtractFreecen2PieceInformation.process_parish(parish, subdistrict_object)
            subdistrict_object.freecen2_civil_parishes << parish_object
          end
        end
      else
        @output_file.puts " No parishes for district #{subdistrict_name} #{subdistrict_tnaid} "
      end

      civil_parish_names = ExtractFreecen2PieceInformation.add_update_civil_parish_list(subdistrict_object)
      subdistrict_object.civil_parish_names = civil_parish_names
      result = subdistrict_object.save
      unless result
        @output_file.puts "piece #{subdistrict_tnaid} #{subdistrict_piece} #{subdistrict_code}"
        @output_file.puts subdistrict_object.errors.full_messages
        crash
      end
      subdistrict_object
    end

    def process_parish(parish, subdistrict_object)
      parish_name = parish['name']
      parish_note = parish['note']
      parish_object = Freecen2CivilParish.new(name: parish_name, note: parish_note, freecen2_piece_id: subdistrict_object.id)
      value = parish['hamlet']
      if value.respond_to?('each_pair')
        hamlet_object = ExtractFreecen2PieceInformation.process_hamlet(value)
        parish_object.freecen2_hamlets << hamlet_object
      elsif value.present?
        value.each do |hamlet|
          hamlet_object = ExtractFreecen2PieceInformation.process_hamlet(hamlet)
          parish_object.freecen2_hamlets << hamlet_object
        end
      end
      result = parish_object.save
      unless result
        @output_file.puts "Parish #{parish_name} "
        @output_file.puts parish_object.errors.full_messages
        crash
      end
      parish_object
    end

    def process_hamlet(hamlet)
      hamlet_name = hamlet['name']
      hamlet_note = hamlet['note']
      hamlet_object = Freecen2Hamlet.new(name: hamlet_name, note: hamlet_note)
      hamlet_object
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

    def add_update_civil_parish_list(piece)
      if piece.freecen2_civil_parishes.blank?
        return nil
      end
      piece.freecen2_civil_parishes.order_by(name: 1).each_with_index do |parish, entry|
        if entry == 0
          @civil_parish_names = parish.name
        else
          @civil_parish_names = @civil_parish_names + ', ' + parish.name
        end
      end
      @civil_parish_names
    end
  end
end
