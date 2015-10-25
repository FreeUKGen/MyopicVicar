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
      record.place = individual.freecen_dwelling.place
      record.freecen_individual = individual
      record.save! 
      
      if record.place.data_present == false
        record.place.data_present = true
        record.place.save!
      end
    end
  end

end