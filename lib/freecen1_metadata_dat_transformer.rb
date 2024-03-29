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
        piece.subplaces_sort = ''
        piece.subplaces.each do |sp|
          unless sp.blank? || sp['name'].blank?
            piece.subplaces_sort += ', ' unless ''==piece.subplaces_sort
            piece.subplaces_sort += sp['name'].downcase
          end
        end
        piece.parish_number = entry.parish_number
        piece.suffix =        entry.suffix
        piece.freecen1_fixed_dat_entry = entry
        piece.year =          freecen1_fixed_dat_file.year
        if piece.film_number.present? && entry.lds_film_number.present? && piece.film_number != entry.lds_film_number
          p " *** #{piece.year} #{piece.chapman_code} #{piece.parish_number}/#{piece.suffix} film=#{piece.film_number} already, another specified #{entry.lds_film_number}"
        end
        piece.film_number = entry.lds_film_number unless piece.film_number.present?
        if piece.freecen1_filename.present? && entry.freecen_filename.present? && piece.freecen1_filename != entry.freecen_filename
          p " *** #{piece.year} #{piece.chapman_code} #{piece.parish_number}/#{piece.suffix} freecen_filename=#{piece.freecen1_filename} already, another specified #{entry.freecen_filename}"
        end
        piece.freecen1_filename = entry.freecen_filename unless piece.freecen1_filename.present?
        piece.save!
      end
      
    end
  end
end
