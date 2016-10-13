module Freecen
  class Freecen1VldTranslator
      
    def translate_file_record(freecen1_vld_file)
      # extract dwellings
      freecen1_vld_file.freecen_dwellings.each do |dwelling|
        translate_dwelling(dwelling, freecen1_vld_file.dir_name, freecen1_vld_file.full_year)
      end      
    end
  
    def translate_dwelling(dwelling, chapman_code, full_year)
      dwelling.freecen_individuals.each do |individual|
        translate_individual(individual, chapman_code, full_year)
      end
    end


  def translate_date(individual, census_year)
    age = individual.age.to_i
    age_unit = individual.age_unit
    
    adjustment = 0 # this is all we need to do for day and week age units
    if age_unit == 'y'
      adjustment = 0 - age
    end
      
    if age_unit == 'm'
      if census_year == RecordType::CENSUS_1841
        # Census day: June 6, 1841 
        #
        # Ages in the 1841 Census
        #    The census takers were instructed to give the exact ages of children 
        # but to round the ages of those older than 15 down to a lower multiple of 5. 
        # For example, a 59-year-old person would be listed as 55. Not all census
        # enumerators followed these instructions. Some recorded the exact age; 
        # some even rounded the age up to the nearest multiple of 5.
        # 
        # Source: http://familysearch.org/learn/wiki/en/England_Census:_Further_Information_and_Description
        adjustment = -1 if age > 6
      elsif census_year == RecordType::CENSUS_1851
        # Census day: March 30, 1851 
        adjustment = -1 if age > 3
      elsif census_year == RecordType::CENSUS_1861
        # Census day: April 7, 1861 
        adjustment = -1 if age > 4
      elsif census_year == RecordType::CENSUS_1871
        # Census day: April 2, 1871
        adjustment = -1 if age > 4
      elsif census_year == RecordType::CENSUS_1881
        # Census day: April 3, 1881 
        adjustment = -1 if age > 4
      elsif census_year == RecordType::CENSUS_1891
        # Census day: April 5, 1891 
        adjustment = -1 if age > 4
      end      
    end

    birth_year = census_year.to_i + adjustment
    
    "#{birth_year}-*-*"
  end


    
    def translate_individual(individual, chapman_code, full_year)
      # create the search record for the person
      transcript_name = { :first_name => individual.forenames, :last_name => individual.surname, :type => 'primary' }
      
      transcript_date = translate_date(individual, full_year)
      
      record = 
        SearchRecord.new({  :transcript_dates => [transcript_date], 
                            :transcript_names => [transcript_name], 
                            :chapman_code => chapman_code, 
                            :record_type => full_year})
      record.place = individual.freecen_dwelling.place
      if !individual.birth_county.blank?
        record.birth_chapman_code = individual.birth_county
      end
      if !individual.verbatim_birth_county.blank?
        record.birth_chapman_code = individual.verbatim_birth_county
      end
      
      record.freecen_individual = individual
      record.transform
      record.add_digest
      record.save! 
      
      if record.place.nil?
        raise "\n\n***ERROR! place was nil for #{full_year}-#{chapman_code} individual=#{individual.inspect}\n  dwelling=#{individual.freecen_dwelling.inspect unless individual.freecen_dwelling.nil?}\n\n"
      end
      if record.place.data_present == false
        record.place.data_present = true
        place_save_needed = true
      end
      if !record.place.cen_data_years.include?(full_year)
        record.place.cen_data_years << full_year
        place_save_needed = true
      end
      record.place.save! if place_save_needed
    end
  end



end
