module Freecen
  class Freecen1VldTranslator
      
    def translate_file_record(freecen1_vld_file)
      # extract households
      freecen1_vld_file.freecen_households.each do |household|
        translate_household(household)
      end      
    end
  
    def translate_household(household)
      household.freecen_individuals.each do |individual|
        translate_individual(individual)
      end
    end
    
    def translate_individual(individual)
      # create the search record for the person
      transcript_name = { :first_name => individual.forenames, :last_name => individual.surname, :type => 'primary' }
      
      transcript_date = individual.freecen_household.freecen1_vld_file.full_year.to_s
      record = SearchRecord.new({ :transcript_dates => [transcript_date], :transcript_names => [transcript_name]})
      
      record.freecen_individual = individual
      
      record.save! 
    end
    
  
  end
end