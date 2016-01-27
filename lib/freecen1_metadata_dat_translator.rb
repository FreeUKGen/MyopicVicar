module Freecen
  class Freecen1MetadataDatTranslator
      
    def translate_file_record(freecen1_fixed_dat_file)
      # extract dwellings
      freecen1_fixed_dat_file.freecen1_fixed_dat_entries.each do |entry|
        # binding.pry unless entry.freecen_piece
        translate_piece(entry.freecen_piece)
      end      
    end
  
    def translate_piece(piece)
      # pp piece.attributes
      place = existing_place_for_piece(piece)
      unless place
        place = Place.new
        place.chapman_code = piece.chapman_code
        place.place_name = piece.district_name
      end 
#      piece.subplaces.each do |subplace|
#        place.alternateplacenames << Alternateplacename.new(:alternate_name => subplace) unless place.alternateplacenames.where(:alternate_name => subplace).count > 0
#      end
      place.latitude = 60 # TODO handle for FreeCEN
      place.longitude = 0
      place.save!
      
      piece.place = place
      piece.save!
      # pp place.attributes
      # print "\n\n"
    end
    
    def existing_place_for_piece(piece)
      place = Place.where(:chapman_code => piece.chapman_code, :place_name => piece.district_name).first
      
      place      
    end  
  end
end
