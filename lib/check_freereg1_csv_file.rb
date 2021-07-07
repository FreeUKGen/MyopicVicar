module CheckFreereg1CsvFile
  class << self
    def check_county(file, fix)
      check = false
      register = file.register
      if register.blank?
        reason = 'No register'
        return [check, reason]
      end
      church = register.church
      if church.blank?
        reason = 'No church'
        return [check, reason]
      end
      place = church.place
      if place.blank?
        reason = 'No place'
        return [check, reason]
      end
      if place.country.blank?
        reason += "Country, #{place.place_name},Blank," if reason.present?
        reason = "Country, #{place.place_name},Blank," if  reason.blank?
        place.country = place.get_correct_place_country if fix
        place.save if fix
      end
      if place.chapman_code != file.county
        reason += "County, #{place.chapman_code},#{file.county}," if reason.present?
        reason = "County, #{place.chapman_code},#{file.county}," if reason.blank?
        file.county = place.chapman_code if fix
      end
      if place.place_name != file.place
        reason += "Place, #{place.place_name}, #{file.place}," if reason.present?
        reason = "Place, #{place.place_name}, #{file.place}," if reason.blank?
        file.place = place.place_name if fix
      end
      if church.church_name != file.church_name
        reason += "Church, #{church.church_name},#{file.church_name}," if reason.present?
        reason = "Church, #{church.church_name},#{file.church_name}," if reason.blank?
        file.church_name = church.church_name if fix
      end
      if register.register_type != file.register_type
        reason += " Register, #{register.register_type},#{file.register_type}," if reason.present?
        reason = "Register, #{register.register_type},#{file.register_type}," if reason.blank?
        file.register_type = register.register_type if fix && file.register_type != 'Unspecified'
      end
      #entry = file.freereg1_csv_entries.first
      #search_record = entry.search_record
      #search_place, search_church, search_register = search_record.extract_location_parts

      #if place.place_name != search_place
      #reason += "Search Place, #{place.place_name}, #{search_place}," if reason.present?
      #reason = "Search Place, #{place.place_name}, #{search_place}," if reason.blank?
      #end
      #if church.church_name != search_church
      #reason += "Search Church, #{church.church_name},#{search_church}," if reason.present?
      #reason = "Search Church, #{church.church_name},#{search_church}," if reason.blank?
      #end
      #if register.register_type != search_register
      #reason += " Search Register, #{register.register_type},#{search_register}," if reason.present?
      #reason = "Search Register, #{register.register_type},#{search_register}," if reason.blank?
      #end
      check = true if reason.blank?
      file.save if fix && !check
      reason = ''  if reason.blank?
      p "#{check} #{reason} " if !check
      [check, reason]
    end

    def check_register_type(file, fix)
      check = false
      register = file.register
      if register.nil?
        reason = 'No register'
        return [check, reason]
      end
      if register.register_type != file.register_type
        reason += " Register, #{register.register_type},#{file.register_type}," if reason.present?
        reason = "Register, #{register.register_type},#{file.register_type}," if reason.blank?
        file.register_type = register.register_type if fix
      end
      check = true if reason.blank?
      file.save if fix && !check
      reason = ''  if reason.blank?
      puts "#{check} #{reason} " if !check
      [check, reason]
    end
  end
end
