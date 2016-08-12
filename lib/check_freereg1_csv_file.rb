module CheckFreereg1CsvFile
  class << self
    def check_county(file,fix)
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
      if place.country.blank?
        reason = reason + "Country, #{place.place_name},Blank,"  if  reason.present?
        reason = "Country, #{place.place_name},Blank," if  reason.blank?
        place.country = place.get_correct_place_country if fix
        place.save if fix
      end

      # if place.country != file.country
      #   reason = reason + "Country, #{place.country},#{file.country},"  if  reason.present?
      #   reason = "Country, #{place.country},#{file.country}," if  reason.blank?
      #  end
      if place.chapman_code != file.county
        reason = reason + "County, #{place.chapman_code},#{file.county},"  if  reason.present?
        reason = "County, #{place.chapman_code},#{file.county}," if  reason.blank?
        file.county = place.chapman_code if fix
      end
      #if place.chapman_code != file.chapman_code
      #reason = reason + "Chapman, #{place.chapman_code},#{file.chapman_code}," if  reason.present?
      #reason = "Chapman, #{place.chapman_code},#{file.chapman_code}," if  reason.blank?
      #end
      if place.place_name != file.place
        reason = reason + "Place, #{place.place_name}, #{file.place},"   if  reason.present?
        reason = "Place, #{place.place_name}, #{file.place},"   if  reason.blank?
        file.place = place.place_name if fix
      end
      #if place.place_name != file.place_name
      # reason = "Place_name, #{place.place_name}, #{file.place_name}," + reason   if  reason.present?
      # reason = "Place_name, #{place.place_name}, #{file.place_name}," if  reason.blank?
      #end
      if church.church_name != file.church_name
        reason = reason + "Church, #{church.church_name},#{file.church_name},"   if  reason.present?
        reason = "Church, #{church.church_name},#{file.church_name}," if  reason.blank?
        file.church_name = church.church_name if fix
      end
      if register.register_type != file.register_type
        reason =   reason + " Register, #{register.register_type},#{file.register_type},"  if  reason.present?
        reason = "Register, #{register.register_type},#{file.register_type}," if  reason.blank?
        file.register_type = register.register_type if fix
      end

      check = true if reason.blank?
      file.save if fix && !check
      reason = ""  if reason.blank?
      p "#{check} #{reason} " if !check
      return [check,reason]
    end

  end

end
