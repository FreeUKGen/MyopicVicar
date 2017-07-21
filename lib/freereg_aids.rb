module FreeregAids
  require 'freereg_options_constants'
  require 'register_type'

  def self.extract_location(line)

    #Place starts the folder name.
    #Underscore starts a Church
    #Hyphen starts some note follows a church or place.
    #Last two characters are Register type.

    register = nil
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
        end
        location_part = line[0...-3]
      end
    else 
      location_part = line
    end

    underscore_parts = location_part.split("_")
    if underscore_parts.count == 2
      place = underscore_parts[0]
      church = underscore_parts[1] #we have a church as well as a place
      church,church_notes = self.extract_note(church)
    else
      place,church_notes = extract_note(location_part)
      church = nil
    end
    # Eric D said there is no place_notes, everything before _ is place
#    place,place_notes = self.extract_note(place) if place.present?
    church = Church.standardize_church_name(church) if church.present?
    return place,church,register,church_notes
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

  def self.check_and_get_location(chapman,place_name,church_name,register,place_part)
    message = Hash.new

    place,message,place_exist = self.check_and_get_place(chapman,place_name) unless chapman.nil? || place_name.nil?
    if place_exist
      church,message,church_status,church_exist = self.check_and_get_church(place,church_name,place_part)
      if church_exist
        register,message,register_status,register_exist = self.check_and_get_register(chapman,place,church,register,place_part)
      end
    end

    if ['C4B', 'C4H'].include?(church_status) || ['R4H'].include?(register_status) || place_exist == false
      status = false
    else
      status = true
    end
    return place,church,register,message,status,church_status,register_status
  end

  def self.check_and_get_place(chapman,place_name)
    message = Hash.new
    place = Place.chapman_code(chapman).modified_place_name(place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase).not_disabled.first
    if place.present?
      place_ok = true
    else
p "========================P1"
      place_ok = false
      message = {:P1 => { chapman => { place_name => "P1: file \"/#{chapman}/#{place_name}\" on IS does not have Place \"#{place_name}\" on FR\r\n\r\n"}}}
#      currently skip all files if related place does not exist in Place yet
    end
    return place,message,place_ok
  end

  def self.check_and_get_church(place,church_name,place_part)
    church_ok = true
    message = Hash.new
    number_of_churches = place.churches.count     #number of churches in collection churches with the given place_id
    church = place.churches.first

    case number_of_churches
    when 0    # no church on FR
      if church_name.nil?   # no church on FR and IS, create church 'To be determined'
p "=======================C4B"
        church_status = 'C4B'
        church_ok = false

        message = {:C4B => { place.chapman_code => { place_part => "C4-B: WARNING: file \"#{place.chapman_code}/#{place_part}\" on IS does not have Church on FR or IS\r\n\r\n"}}}
      else
p "=======================C4A"
        church_status = 'C4A'
        church = create_church(place._id, church_name)

        message = {:C4A => { place.chapman_code => { place_part => "C4-A: WARNING: file \"/#{place.chapman_code}/#{place_part}\" on IS does not have Church \"#{church_name}\" for Place \"#{place.place_name} \"on FR\r\n\r\n"}}}
      end

    when 1    # one church on FR
      if church_name.nil?   # one church on FR, no church on IS, use church on FR
        church_status = 'C4E'
#        update_church(place_id, church_name)

        message = {:C4E => { place.chapman_code => { place_part => "C4-E: file \"#{place.chapman_code}/#{place_part}\" has zero church_name on IS and one on FR, so assume Church \"#{church.church_name}\" on FR is the church\r\n\r\n"}}}
      else 
        if church.church_name.downcase == church_name.downcase    
          church_status = 'GOOD'
#          message = "C4-C: GOOD: file \"#{place.chapman_code}/#{place.place_name}_#{church_name}\" matches the church on FR\r\n\r\n"
        else      # church name on FR and IS are different, create church with church name on IS
p "=======================C5A"
          church_status = 'C5A'
          church = create_church(place._id, church_name)

          message = {:C5A => { place.chapman_code => { place_part => "C5-A: WARNING: file \"/#{place.chapman_code}/#{place_part}\" does not match church \"#{church.church_name}\" on FR\r\n\r\n"}}}
        end
      end
    else    # multiple churches on FR
      if church_name.nil?
p "=======================C4H"
        church_status = 'C4H'
        church_ok = false      # comment out for case 3 in image_test.rake#L53

        message= {:C4H => { place.chapman_code => { place_part => "C4-H: ERROR: file \"/#{place.chapman_code}/#{place_part}\" has no church_name on IS but multiple churches on FR\r\n\r\n"}}}
      else
        place.churches.each do |church|
          if church.church_name.downcase == church_name.downcase
            church_status = 'GOOD'
#            message = "C4-F: GOOD: file \"/#{place.chapman_code}/#{place.place_name}_#{church_name}\" on IS matches church record on FR\r\n\r\n"
            return church,message,church_status,church_ok
          end
        end
p "=======================C5B"
        church_status = 'C5B'
        church_ok = false        # comment out for case 3 in image_test.rake#L53
        church = create_church(place._id, church_name)

        message = {:C5B => { place.chapman_code => { place_part => "C5-B: WARNING: file \"/#{place.chapman_code}/#{place_part}\" on IS does not matach any church on FR\r\n\r\n"}}}
      end
    end
    return church,message,church_status,church_ok
  end

  def self.check_and_get_register(chapman,place,church,register_type,place_part)
    register_ok = true
    message = Hash.new
    register = church.registers.first
    number_of_registers = church.registers.count

    case number_of_registers
    when 0
      if register_type.nil?
p "=======================R4B"
        register_status = 'R4B'
        register = create_register(chapman, place, church, 'OD')

        message = {:R4B => { place.chapman_code => { place_part => "R4-B: WARNING: file \"#{place.chapman_code}/#{place_part}\" on IS does not have register type on FR or IS\r\n\r\n"}}}
      else
p "=======================R4A"
        register_status = 'R4A'
        register = create_register(chapman,place,church,register_type)

        message = {:R4A => { place.chapman_code => { place_part => "R4-A: IGNORE: image not transcribed yet. File \"/#{place.chapman_code}/#{place_part}\" on IS does not have register type \"#{register_type}\" for Place \"#{place.place_name}\" Church \"#{church.church_name}\" on FR\r\n\r\n"}}}
      end
    when 1
      if register_type.nil?
        register_status = 'R4E'

        message = {:R4E => { place.chapman_code => { place_part => "R4-E: WARNING: file \"#{place.chapman_code}/#{place_part}\" has zero register_type on IS and one on FR, so assume \"#{register.register_type}\" is the register_type\r\n\r\n"}}}
      else
        if register.register_type == register_type
          register_status = 'GOOD'
#          message = "file \"/#{place.chapman_code}/#{place.place_name}_#{church.church_name} register_type #{register_type} \" on IS matches register_type on FR\r\n\r\n"
        else
          if register.register_type == ' '
p "=======================R6A1"
            register_status = 'R6A1'
            update_register(register._id, register_type)

            message = {:R6A1 => { place.chapman_code => { place_part => "R6-A1: REPLACE: \"#{register_type}\" will replace \" \" on FR. File \"/#{place.chapman_code}/#{place_part}\" on IS does not match register_type \"#{register.register_type}\" on FR\r\n\r\n"}}}
          else
p "=======================R6A2"
            register_status = 'R6A2'
            register = create_register(chapman,place,church,register_type)

            message = {:R6A2 => { place.chapman_code => { place_part => "R6-A2: WARNING: file \"/#{place.chapman_code}/#{place_part}\" on IS does not match register_type \"#{register.register_type}\" on FR\r\n\r\n"}}}
          end
        end
      end
    else
      if register_type.nil?
p "=======================R4H"
        register_status = 'R4H'
        register_ok = false

        message = {:R4H => { place.chapman_code => { place_part => "R4-H: ERROR: file \"/#{place.chapman_code}/#{place_part}\" has no register_type on IS but multiple register types on FR\r\n\r\n"}}}
      else
        id = nil
        church.registers.each do |reg|
          if reg.register_type == register_type
            register_status = 'GOOD'
            return reg,message,register_status,register_ok
          end
          if reg.register_type == ' '
            id = reg._id
            register = reg              
          end
        end
      end

      if id.nil?
p "=======================R6B2"
        register_status = 'R6B2'
        register = create_register(chapman,place,church,register_type)

        message = {:R6B2 => { place.chapman_code => { place_part => "R6-B2: WARNING: file \"/#{place.chapman_code}/#{place_part}\" on IS does not match any register_type on FR\r\n\r\n"}}}
      else
p "=======================R6B1"
        register_status = 'R6B1'
        update_register(id, register_type)

        message = {:R6B1 => { place.chapman_code => { place_part => "R6-B1: REPLACE: \"#{register_type}\" will replace \" \" on FR. File \"/#{place.chapman_code}/#{place_part}\" on IS does not match any register_type on FR\r\n\r\n"}}}
      end        
    end

    return register,message,register_status,register_ok
  end

  def self.create_church(place_id,church_name)
    church_name = Church.standardize_church_name(church_name)
    church = Church.new(:place_id=>place_id, :IS_church_name=>church_name)
    church.calculate_church_numbers      # do not have collection FreeregValidations in database

    church.save!
    place.churches << church
    place.save!
p "CREATE CHURCH: place="+place_id.to_s+" church="+church_name.to_s

    return church
  end

  def self.update_church(place_id, church_name)
    church = Church.find({:place_id=>place_id, :church_name=>church_name})
    church.IS_church_name = church_name
    church.save!

p "UPDATE CHURCH: place="+place_id.to_s+" church="+church_name.to_s
  end

  def self.create_register(chapman,place,church,register_type)
    register = Register.new(:church_id=>church.id, :register_type=>register_type)
    register.church_id = church.id
    register.register_type = register_type
    register.last_amended = Time.now.strftime("%d %b %Y")
    register.register_notes = 'Created by IS_FR loading script'

    register.save!
    church.registers << register
    church.save!
p "CREATE REGISTER: place="+place.place_name.to_s+" church="+church.church_name.to_s+" register="+register_type.to_s+" register id="+register.id.to_s

    return register
  end

  def self.update_register(register_id, register_type)
    register = Register.find({:id=>register_id})
    register.register_type = register_type
    register.save!

p "UPDATE REGISTER: place="+register[:place_name].to_s+" church="+register[:church_name].to_s+" register_tye="+register_type.to_s+" id="+register_id.to_s
  end

end