require 'freecen_constants'

module Freecen
  class Freecen1VldTransformer
      
    def transform_file_record(freecen1_vld_file)
      dwelling = nil
      freecen1_vld_file.freecen1_vld_entries.each do |entry|
        if dwelling && dwelling.dwelling_number == entry.dwelling_number
          # do nothing -- the dwelling on this record is the same as for the previous entry
        else
          # save previous dwelling
          dwelling.save! if dwelling
          
          # first record or different record
          dwelling = dwelling_from_entry(entry)
        end
        unless dwelling.uninhabited_flag.match(Freecen::Uninhabited::UNINHABITED_PATTERN)
          individual_from_entry(entry, dwelling)
        end
      end
      dwelling.save!
      
    end

  
    def dwelling_from_entry(entry)
      dwelling = FreecenDwelling.new
      (FreecenDwelling.fields.keys&Freecen1VldEntry.fields.keys).each do |key|
        dwelling[key] = entry.send(key) unless key == "_id"
      end
      dwelling.freecen1_vld_file=entry.freecen1_vld_file
      dwelling.place = check_and_get_place(dwelling, entry.freecen1_vld_file.chapman_code)
      
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
    
    def check_and_get_place(dwelling, chapman_code)
      chapman_code = dwelling.freecen1_vld_file.chapman_code
      if false # this block disabled (uses civil_parish as place)
        place_name = dwelling.civil_parish
        place = Place.where(:chapman_code => chapman_code, :place_name => dwelling.civil_parish).first
      
        if nil == place
          place = Place.create!(:chapman_code => chapman_code, :place_name => dwelling.civil_parish, :latitude => 50, :longitude => 0)
        end
        return place
      else # use DAT file places as before
        piece_number = dwelling.freecen1_vld_file.piece
        chapman_code = dwelling.freecen1_vld_file.chapman_code

        piece = FreecenPiece.where(:chapman_code => chapman_code, :piece_number => piece_number).first
        
        unless piece
          raise "No FreecenPiece found for chapman code #{chapman_code} and piece number #{piece_number}. year=#{dwelling.freecen1_vld_file.full_year} dir=#{dwelling.freecen1_vld_file.dir_name} file=#{dwelling.freecen1_vld_file.file_name}\nRun rake freecen:process_freecen1_metadat_dat for the appropriate county.\n"
        end
        return piece.place
      end
    end
  end
end
