 module CheckSearchRecord
  class << self
    def check_search_record_location_and_county(file)
      check = false
      entry_ids = file.freereg1_csv_entry_ids
      if entry_ids[0].nil?
        reason = "No entries"
        return [check,reason] 
      end
      entry = Freereg1CsvEntry.find(entry_ids[0])
      if entry.nil?
        reason = "No entries"
        return [check,reason] 
      end
      record = entry.search_record
      if record.nil?
        reason = "No search record"
        return [check,reason] 
      end
      register = file.register
      if register.nil?
        reason = "No register"
        return [check,reason] 
      end
      church = register.church
      if church.nil?
        reason = "No church"
        return [check,reason] 
      end 
      place = church.place
      if place.nil?
        reason = "No place"
        return [check,reason] 
      end 
      location = record.location_names
      chapman = record.chapman_code
      register_type = RegisterType.display_name(register.register_type)
      record_location_names = []
      record_location_names << "#{place.place_name} (#{church.church_name})" 
      record_location_names << " [#{register_type}]"
      unless record_location_names[0].strip == location[0].strip 
        reason = "#{record_location_names[0]}, #{location[0]}"      
      end 
       unless record_location_names[1].strip == location[1].strip 
        unless record_location_names[1].strip == "[Unspecified]"
          reason = "#{record_location_names[1]}, #{location[1]}," + reason if  reason.present? 
          reason = "#{record_location_names[1]}, #{location[1]}" if  reason.blank? 
        end 
      end 
      if place.chapman_code != chapman
        reason = "#{place.chapman_code}, #{chapman}," + reason if  reason.present? 
        reason = "#{place.chapman_code}, #{chapman}" if  reason.blank? 
      end 

      check = true if reason.blank? 
      reason = "" if reason.blank? 
      p "#{check} #{reason}" if !check
      return [check,reason] 
    end
    def correct_record_location_fields(file)
      fixed = 0
      register = file.register
      church = register.church
      place = church.place 
      place_name = place.place_name
      church_name = church.church_name 
      chapman = place.chapman_code
      register_type = RegisterType.display_name(register.register_type)
      location_names =[]
      location_names << "#{place_name} (#{church_name})"
      location_names  << " [#{register_type}]"
      file.freereg1_csv_entries.all.no_timeout.each do |entry|
        record = entry.search_record
        entry.update_attribute(:register_type,register.register_type)
        if record.present?
         fixed = fixed + 1
         record.update_attributes(:location_names => location_names, :chapman_code => chapman)
         record.update_attribute(:place_id, place._id) if record.place_id != place._id
         sleep_time = (Rails.application.config.sleep.to_f).to_f
         sleep(sleep_time)   
        else
         p "FREEREG:search record missing for entry #{entry._id}"  
        end
      end
      fixed
    end
    def correct_county_instead_of_chapman(county)
      SearchRecord.chapman_code(county).no_timeout.each do |record|
        record.update_attribute(:chapman_code,ChapmanCode.values_at(county))
      end
    end
  end
end