module CheckFreereg1CsvFile
 class << self
    def check_county(file)     
      check = false    
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
      if place.place_name != file.place
        reason = "#{place.place_name}, #{file.place}"
      end
      if church.church_name != file.church_name
        reason = "#{church.church_name},#{file.church_name}," + reason   if  reason.present? 
        reason = "#{church.church_name},#{file.church_name}" if  reason.blank? 
      end
      if register.register_type != file.register_type
        reason =   "#{register.register_type},#{file.register_type}," + reason  if  reason.present? 
        reason = "#{register.register_type},#{file.register_type}" if  reason.blank? 
      end
      if place.chapman_code != file.county
        reason = "#{place.chapman_code},#{file.county}," + reason if  reason.present? 
        reason = "#{place.chapman_code},#{file.county}" if  reason.blank? 
      end
      check = true if reason.blank? 
      reason = ""  if reason.blank? 
         p "#{check} #{reason} " if !check
      return [check,reason]
    end

    def correct_file_location_fields(file)
      register = file.register
      church = register.church
      place = church.place 
      place_name = place.place_name
      church_name = church.church_name 
      chapman = place.chapman_code
      file.update_attributes(:place => place_name, :church_name => church_name, :register_type => register.register_type, :county => chapman)   
    end
  end
end