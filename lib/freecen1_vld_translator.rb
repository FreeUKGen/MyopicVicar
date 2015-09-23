module Freecen
  class Freecen1VldTranslator
      
    def translate_file_record(freecen1_vld_file)
      # extract dwellings
      freecen1_vld_file.freecen_dwellings.each do |dwelling|
        translate_dwelling(dwelling, freecen1_vld_file.dir_name)
      end      
    end
  
    def translate_dwelling(dwelling, chapman_code)
      dwelling.freecen_individuals.each do |individual|
        translate_individual(individual, chapman_code)
      end
    end
    
    def translate_individual(individual, chapman_code)
      # create the search record for the person
      transcript_name = { :first_name => individual.forenames, :last_name => individual.surname, :type => 'primary' }
      
      transcript_date = individual.freecen_dwelling.freecen1_vld_file.full_year.to_s
      record = SearchRecord.new({ :transcript_dates => [transcript_date], :transcript_names => [transcript_name], :chapman_code => chapman_code})
      record.place = check_and_get_place(individual.freecen_dwelling, chapman_code)
      record.freecen_individual = individual
      record.save! 
    end
    
    def check_and_get_place(dwelling, chapman_code)
      piece_number = dwelling.freecen1_vld_file.piece
      chapman_code = dwelling.freecen1_vld_file.chapman_code
      
      piece = FreecenPiece.where(:chapman_code => chapman_code, :piece_number => piece_number).first
      
      unless piece
        raise "No FreecenPiece found for chapman code #{chapman_code} and piece number #{piece_number}.\nRun rake freecen:process_freecen1_metadat_dat for the appropriate county.\n"      
      end
      
      piece.place
    end
  end
end