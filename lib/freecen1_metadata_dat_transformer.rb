require 'freecen_constants'

module Freecen
  class Freecen1MetadataDatTransformer
      
    def transform_file_record(freecen1_fixed_dat_file)
      freecen1_fixed_dat_file.freecen1_fixed_dat_entries.each do |entry|
        piece = FreecenPiece.new
        piece.chapman_code =  freecen1_fixed_dat_file.chapman_code
        piece.piece_number =  entry.piece_number
        piece.district_name = entry.district_name
        piece.subplaces =     entry.subplaces
        piece.parish_number = entry.parish_number
#        piece.suffix =        entry.suffix
        piece.freecen1_fixed_dat_entry = entry
        piece.save!
      end
      
    end
  end
end
