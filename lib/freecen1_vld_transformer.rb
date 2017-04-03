require 'freecen_constants'

module Freecen
  class Freecen1VldTransformer
      
    def transform_file_record(freecen1_vld_file)
      dwelling = nil
      piece = check_and_get_piece_for_file(freecen1_vld_file)
      piece.freecen1_filename = freecen1_vld_file.file_name
      piece.status = 'Loading' if piece.status != 'Loading'
      piece.save!
      Rails.cache.delete("freecen_coverage_index")#bust cache so status shows
      freecen1_vld_file.freecen1_vld_entries.each do |entry|
        if dwelling && dwelling.dwelling_number == entry.dwelling_number
          # do nothing -- the dwelling on this record is the same as for the previous entry
        else
          # save previous dwelling
          dwelling.save! if dwelling
          
          # first record or different record
          dwelling = dwelling_from_entry(entry, piece)
        end
        unless dwelling.uninhabited_flag.match(Freecen::Uninhabited::UNINHABITED_PATTERN)
          individual_from_entry(entry, dwelling)
          unless piece.nil?
            piece.inc(:num_individuals => 1)
          end
        end
      end
      dwelling.save!
      piece.save! unless piece.nil?
    end

  
    def dwelling_from_entry(entry, piece)
      dwelling = FreecenDwelling.new
      (FreecenDwelling.fields.keys&Freecen1VldEntry.fields.keys).each do |key|
        dwelling[key] = entry.send(key) unless key == "_id"
      end
      dwelling.freecen1_vld_file=entry.freecen1_vld_file
      dwelling.freecen_piece = piece
      dwelling.place = nil
      dwelling.place = piece.place unless piece.nil?
      dwelling
    end
    
    def individual_from_entry(entry, dwelling)
      individual = FreecenIndividual.new
      (FreecenIndividual.fields.keys&Freecen1VldEntry.fields.keys).each do |key|
        individual[key] = entry.send(key) unless key == "_id"
      end
      individual.freecen1_vld_entry=entry
      individual.freecen_dwelling=dwelling
      individual.save!
      
      individual    
    end

    def check_and_get_piece_for_file(freecen1_vld_file)
      year = freecen1_vld_file.full_year
      piece_number = freecen1_vld_file.piece
      chapman_code = freecen1_vld_file.chapman_code #or .dir_name
      sctpar = freecen1_vld_file.sctpar
      piece = FreecenPiece.where(:year => year, :chapman_code => chapman_code, :piece_number => piece_number, :parish_number => sctpar)
      if piece.count > 1
        piece_list = " count=#{piece.count}\n"
        piece.each do |pc|
          pc.status = 'Error (not unique)'
          pc.save!
          piece_list += " [#{pc.inspect}]\n"
        end
        raise "Multiple FreecenPieces found for chapman code #{chapman_code} and piece number #{piece_number}. year=#{year} dir=#{freecen1_vld_file.dir_name} file=#{freecen1_vld_file.file_name}\n#{piece_list}\n"
      end
      piece = piece.first
      unless piece
        raise "No FreecenPiece found for chapman code #{chapman_code} and piece number #{piece_number}. year=#{year} dir=#{freecen1_vld_file.dir_name} file=#{freecen1_vld_file.file_name}\nRun rake freecen:process_freecen1_metadat_dat for the appropriate county.\n"
      end
      return piece
    end
  end
end
