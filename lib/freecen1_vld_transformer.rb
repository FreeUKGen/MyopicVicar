require 'freecen_constants'

module Freecen
  class Freecen1VldTransformer
      
    def transform_file_record(freecen1_vld_file)
      # extract places
      # extract pieces
      # extract household
      # extract individual
      household = nil
      freecen1_vld_file.freecen1_vld_entries.each do |entry|
        if household && household.entry_number == entry.entry_number
          # do nothing -- the household on this record is the same as for the previous entry
        else
          # save previous household
          household.save! if household
          
          # first record or different record
          household = household_from_entry(entry)
        end
        unless household.uninhabited_flag.match(Freecen::Uninhabited::UNINHABITED_PATTERN)
          household.freecen_individuals << individual_from_entry(entry)
        end
      end
      household.save!
      
    end
  
    def household_from_entry(entry)
      household = FreecenHousehold.new
      (FreecenHousehold.fields.keys&Freecen1VldEntry.fields.keys).each do |key|
        household[key] = entry.send(key) unless key == "_id"
      end
      household.freecen1_vld_file=entry.freecen1_vld_file
      
      household
    end
    
    def individual_from_entry(entry)
      individual = FreecenIndividual.new
      (FreecenIndividual.fields.keys&Freecen1VldEntry.fields.keys).each do |key|
        individual[key] = entry.send(key) unless key == "_id"
      end
      individual.freecen1_vld_entry=entry
      
      individual    
    end
    
  
  end
end