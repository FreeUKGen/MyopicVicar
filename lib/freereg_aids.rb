module FreeregAids
  require 'freereg_options_constants'
  require 'register_type'

  def self.extract_location(line)

    #Place starts the folder name.
    #Underscore starts a Church
    #Hyphen starts some note follows a church or place.
    #Last two characters are Register type.
    register_part = line.chars.last(3).join.strip
    if register_part.chars.length == 2 && register_part == register_part.upcase
      possible_register_type = register_part # within county folder, there are files e.g. xxxx.gif instead of another folder
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
        location_part = line[0...-3]
        line_parts = location_part.split("_")
        if line_parts.count == 2
          place = line_parts[0]
          church = line_parts[1] #we have a church as well as a place
        else
          place = location_part  #no church just a place and register type
          church = nil
        end
        place_notes,church_notes = ''
        place,place_notes = self.extract_note(place) if place.present?
        church,church_notes = self.extract_note(church) if church.present?
        church = Church.standardize_church_name(church) if church.present?
        place_notes.present? ? notes = place_notes + church_notes.to_s : notes = church_notes.to_s
        return place,church,register,notes
      end
    end
  end

  def self.extract_note(word)
    word_parts = word.split("-", 2)
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
    message = Hash.new

    register_exist = true
    place,message,place_exist = self.check_and_get_place(chapman,place_name) unless chapman.nil? || place_name.nil?
    if place_exist
      church,message,church_exist = self.check_and_get_church(place,church_name)
      if church_exist
#        register,message,register_exist = self.check_and_get_register(chapman,place,church,register)
      end
    end

    if place_exist && church_exist && register_exist
      final_success = true
    else
      final_success = false
    end
    return place,church,register,message,final_success

  end

  def self.check_and_get_place(chapman,place_name)
    message = Hash.new
    place = Place.chapman_code(chapman).modified_place_name(place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase).not_disabled.first
    if place.present?
      place_ok = true
#      message = "Place #{place_name} found\r\n"
    else
      place_ok = false
      message = {:L1 => { chapman => { place_name => "L1: file \"/#{chapman}/#{place_name}\" on IS does not have Place \"#{place_name}\" on FR\r\n\r\n"}}}
    end
    return place,message,place_ok
  end

  def self.check_and_get_church(place,church_name)
    church_ok = true
    message = Hash.new
    number_of_churches = place.churches.count     #number of churches in collection churches with the given place_id

    case number_of_churches
    when 0    # no church on FR
      if church_name.nil?   # no church on FR and IS, create church 'To be determined'
        church_name = 'To be determined'
#        message = "L4-B: file \"#{place.chapman_code}/#{place.place_name}\" on IS does not have Church on FR or IS\r\nadd church \"To be determined\" for county #{place.chapman_code} place \"#{place.place_name}\" on FR\r\n\r\n"
        message = {:L4B => { place.chapman_code => { place.place_name => "L4-B: WARNING: file \"#{place.chapman_code}/#{place.place_name}\" on IS does not have Church on FR or IS\r\n\r\n"}}}
      else
#        message = "L3-A: file \"/#{place.chapman_code}/#{place.place_name}_#{church_name}\" on IS does not have Church on FR\r\nadd church \"#{church_name}\" for county #{place.chapman_code} place \"#{place.place_name}\ on FR\r\n\r\n"
        message = {:L4A => { place.chapman_code => { place.place_name => "L4-A: WARNING: file \"/#{place.chapman_code}/#{place.place_name}_#{church_name}\" on IS does not have Church \"#{church_name}\" for Place \"#{place.place_name} \"on FR\r\n\r\n"}}}
      end
      create_place_and_church(place._id, church_name)
    when 1    # one church on FR
      church = place.churches.first
      if church_name.nil?   # one church on FR, no church on IS, use church on FR
#        message = "L4-E: file \"#{place.chapman_code}/#{place.place_name}\" has no church_name on IS and one on FR, so assume church \"#{church.church_name}\" on FR is the church, \r\n\r\n"
        message = {:L4E => { place.chapman_code => { place.place_name => "L4-E: WARNING: file \"#{place.chapman_code}/#{place.place_name}\" has zero church_name on IS and one on FR, so assume Church \"#{church.church_name}\" on FR is the church\r\n\r\n"}}}
      else 
        if church.church_name.downcase == church_name.downcase    # church name on FR and IS are the same
#          message = "L4-C: GOOD: file \"#{place.chapman_code}/#{place.place_name}_#{church_name}\" matches the church on FR\r\n\r\n"
        else      # church name on FR and IS are different, create church with church name on IS
#          create_place_and_church(place._id, church_name)
#          message = "L5-A: file \"/#{place.chapman_code}/#{place.place_name}_#{church_name}\" does not match church \"#{church.church_name}\" on FR, \r\nadd church \"#{church_name}\" for county #{place.chapman_code} place \"#{place.place_name}\" on FR\r\n\r\n"
          message = {:L5A => { place.chapman_code => { place.place_name => "L5-A: WARNING: file \"/#{place.chapman_code}/#{place.place_name}_#{church_name}\" does not match church \"#{church.church_name}\" on FR\r\n\r\n"}}}
        end
      end
    else    # multiple churches on FR
      if church_name.nil?
        church = place.churches.first
#        message = "L4-H: ERROR: file \"/#{place.chapman_code}/#{place.place_name}\" has no church_name on IS but multiple churches on FR, will not process until a Church is picked manually\r\n\r\n"
        message= {:L4H => { place.chapman_code => { place.place_name => "L4-H: ERROR: file \"/#{place.chapman_code}/#{place.place_name}\" has no church_name on IS but multiple churches on FR\r\n\r\n"}}}
        church_ok = false
      else
        place.churches.each do |church|
          if church.church_name.downcase == church_name.downcase
#            message = "L4-F: GOOD: file \"/#{place.chapman_code}/#{place.place_name}_#{church_name}\" on IS matches church record on FR\r\n\r\n"
            return church,message,church_ok
          end
        end
#        create_place_and_church(place._id, church_name)
#        message = "L5-B: file \"/#{place.chapman_code}/#{place.place_name}_#{church_name}\" on IS has does not match any church on FR,\r\nadd church \"#{church_name}\" for county #{place.chapman_code} place \"#{place.place_name}\" on FR\r\n\r\n"
        message = {:L5B => { place.chapman_code => { place.place_name => "L5-B: WARNING: file \"/#{place.chapman_code}/#{place.place_name}_#{church_name}\" on IS does not matach any chruch on FR\r\n\r\n"}}}
      end
    end
    return church,message,church_ok
  end

  def self.check_and_get_register(chapman,place,church,register_type)
    regsiter_ok = true
p "====place: "+place.place_name+"     church: "+church.church_name+"     register_type: "+register_type
    number_of_registers = church.registers.count

    case number_of_registers
    when 0
      if register_type.nil?
        message = "file \"/#{place.chapman_code}/#{place.place_name}_#{church.church_name}\" on IS has no register type in FR or IS, going to create new document use value OD in FR\r\n\r\n"
#        create_register(chapman, place, church, 'OD')
      else
        message = "file \"/#{place.chapman_code}/#{place.place_name}_#{church.church_name} #{register_type}\" on IS has no register type in FR, going to create new document use the IS value \"#{register_type}\" in FR\r\n\r\n"
        register = Register.new(:register_type => register_type)
#        create_register(chapman, place, church, register_type)
      end
    when 1
      register = church.registers.first
      if register_type.nil?
        message = "file \"/#{place.chapman_code}/#{place.place_name}_#{church.church_name}\" on IS has no register_type on IS and one on FR, so assume \"#{register.register_type}\" is the register_type\r\n\r\n"
      else
        if register.register_type == register_type
          message = "file \"/#{place.chapman_code}/#{place.place_name}_#{church.church_name} register_type #{register_type} \" on IS matches register_type on FR\r\n\r\n"
        else
          register_ok = false
          register.register_type.blank? ? type  = "Unspecified" : type = register.register_type
          message = "ERROR: file \"/#{place.chapman_code}/#{place.place_name}_#{church.church_name} register_type #{register_type} \" on IS but FR is \"#{type}\", will not process\r\n\r\n"
        end
      end
    else
      church.registers.each do |register|
        if register.register_type == register_type
          message = " register found"
          return register,message,register_ok
        end
      end
      register = nil
      register_ok = false
      message = "ERROR: file \"/#{place.chapman_code}/#{place.place_name}_#{church.church_name} register_type #{register_type} \" on IS but no register match on FR will not process\r\n\r\n"
    end
    #p " +bottom return"
    return register,message,register_ok
  end

  def self.create_place_and_church(place_id,church_name)
# how to call churches_controller.rb#create
# how to call places_controller.rb#create
    #church_name = Church.standardize_church_name(church_name)
    #church = Church.new(:church_name => church_name, :place_id => place_id)
#    church.calculate_church_numbers      # do not have collection FreeregValidations in database
    #church.save!
#    place.chruches << church
#   place.save!
  end

  def self.create_register(church,register_type)
    register = Register.new(:register_type => register_type)
    register.chapman_code = chapman
    register.place_name = place.place_name
    register.church_id = church.church_id
    register.church_name = church.church_name
#    register.save!
#    church.registers << register
#    church.save!
  end

end
