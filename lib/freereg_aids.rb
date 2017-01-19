module FreeregAids
  require 'freereg_options_constants'
  require 'register_type'

  def self.extract_location(line)

    #Place starts the folder name.
    #Hyphen starts some note.
    #Underscore starts a Church
    #Last two characters are Register type.
    possible_register_type = line.chars.last(2).join
    if possible_register_type =~ FreeregOptionsConstants::VALID_REGISTER_TYPES
      # deal with possible register type; clean up variations before we check
      possible_register_type = possible_register_type.gsub(/\(?\)?'?"?[Ss]?/, '')
      possible_register_type = Unicode::upcase(possible_register_type)
      if RegisterType::OPTIONS.values.include?(possible_register_type)
        register = possible_register_type
        register = "DW" if register == "DT"
        register = "PH" if register == "PT"
        register = "TR" if register == "OT"
      else
        register = " "
      end
    end
    reduced_line = line[0...-2]
    line_parts = reduced_line.split("_")
    if line_parts.count == 2
      church = line_parts[1] #we have a church as well as a place
      place = line_parts[0]
    else
      place = reduced_line#no church just a place and register type
      church = nil
    end
    place,notes = self.extract_note(place)
    notes2 = ""
    church,notes2 = self.extract_note(church) if church.present?
    church = Church.standardize_church_name(church) if church.present?
    notes.present? ? notes = notes + notes2 : notes = notes2
    return place,church,register,notes

  end

  def self.extract_note(word)
    word_parts = word.split("-")
    if word_parts.count == 2
      main = word_parts[0].strip
      notes = word_parts[1].strip
    else
      main = word.strip
      notes = ""
    end
    return main,notes
  end

  def self.check_and_get_location(chapman,place_name,church_name,register)
    message = ""
    message1 = ""
    message2 = ""
    final_message = ""
    place,message,success = self.get_and_check_place(chapman,place_name)
    #@p "#{place}, #{message} #{success}"
    church,message1,success1 = self.check_and_get_church(place,church_name) if success
    # p "#{church}, #{message1} #{success1}"
    register,message2,success2 = self.check_and_get_register(church,register) if success1
    #p "#{register}, #{message2}, #{success2}"
    final_message = message unless message.nil?
    final_message = final_message + message1 unless message1.nil?
    final_message = final_message + message2 unless message2.nil?
    unless (success || success1 || success2)
      final_success = true
    else
      final_success = false
    end
    return place,church,register,final_message,final_success

  end

  def self.get_and_check_place(chapman,place_name)
    # p "checking place"
    place = Place.chapman_code(chapman).modified_place_name(place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase).not_disabled.first
    if place.present?
      place_ok = true
      message = "Place #{place_name} found,"
    else
      place_ok = false
      message = "No place of name #{place_name},"
    end
    return place,message,place_ok
  end

  def self.check_and_get_church(place,church_name)
    #p "Checking church"
    number_of_churches = place.churches.count
    case number_of_churches
    when  0
      if church_name.nil?
        message = " no church name in FR or IS creating one on FR named \"Needs Setting\","
        church_name = "Needs Setting"
        church = Church.new(:church_name => church_name)
        church_ok = true
        #place.churches << church
        return church,message,church_ok
      end
      church = Church.new
      church.church_name = Church.standardize_church_name(church_name)
      #place.churches << church
    when 1
      church = place.churches.first
      if church_name.nil?

        # p church
        message = " no church_name on IS only one on FS so assume that #{church.church_name} is the church,"
        church_ok = true
      else
        #p "checking #{church.church_name}"
        if church.church_name.downcase == church_name.downcase
          church_ok = true
          message = " church name #{church_name} on IS matches church on FR,"
        else
          church_ok = false
          message = " church name of #{church_name} on IS does not match #{church.church_name} on FR will not process, "
        end
      end
    else
      if church_name.nil?
        church = place_churches.first
        message = " no church_name on IS but there are multiple churches on FR will not process,"
        church_ok = false
      else
        #p "checking #{church.church_name}"
        place_churches.each do |church|
          if church.church_name.downcase == church_name.downcase
            church_ok = true
            message = " church name #{church_name} on IS matches church on FR,"
            return church,message,church_ok
          end
        end
        #p "fallen through"
        church = nil
        church_ok = false
        message = ' church_name on IS but there is no match on FR will not process,'
      end
    end
    #p " +bottom return"

    return church,message,church_ok
  end

  def self.check_and_get_register(church,register_type)
    # p "checking register #{register_type}"
    number_of_registers = church.registers.count
    case number_of_registers
    when 0
      if register_type.nil?
        message = " no register type in FR or IS going to create one for FR called OD"
        register_type = "OD"
        register = Register.new(:register_type => register_type)
        register_ok = true
        #church.registers << register
      else
        message = " no register type in FR going to use the IS value of #{register_type}"
        register = Register.new(:register_type => register_type)
        register_ok = true
        #church.registers << register
      end
    when 1
      register = church.registers.first
      if register_type.nil?

        message = " no register_type on IS only one on FS so assume that #{register.register_type} is the register_type,"
        register_ok = true
      else
        #p "checking #{church.church_name}"
        if register.register_type == register_type
          register_ok = true
          message = " register_type #{register_type} on IS matches register_type on FR,"
        else
          register_ok = false
          register.register_type.blank? ? type  = "Unspecified" : type = register.register_type
          message = " register_type #{register_type} on IS but #{type}  on FR will not process, "
        end
      end
    else
      church.registers.each do |register|
        if register.register_type == register_type
          register_ok = true
          message = " register found"
          return register,message,register_ok
        end
      end
      register = nil
      register_ok = false
      message = ' register is on IS but no register match on FR will not process '
    end
    #p " +bottom return"
    return register,message,register_ok
  end
end
