module Freereg1CsvFilesHelper

  def get_place(county,name)
    place = Place.where(:chapman_code => county, :place_name => name).first
  end
  def church_name(file)
    church_name = file.church_name
    if church_name.blank?
      register = get_register_object(file)
      church = get_church_object(register)
      church_name = church.church_name unless church.blank?
    end
    church_name
  end
  def userid(file)
    userid = file.userid
  end
  def register_type(file)
    register_type = file.register_type
    if register_type.blank?
      register = get_register_object(file)
      register_type = RegisterType.display_name(register.register_type) unless register.blank?
      file.update_attribute(:register_type, register_type) unless register.blank?
    else
      register_type = RegisterType.display_name(register_type)
    end

    register_type
  end
  def county_name(file)
    county_name = file.county #note county has chapman in file and record)
    case
    when ChapmanCode.value?(county_name)
      county_name = ChapmanCode.name_from_code(county_name)
    when ChapmanCode.key?(county_name)
    else
      register = get_register_object(file)
      church = get_church_object(register)
      place = get_place_object(church)
      county_name = place.county unless place.blank?
    end
    county_name
  end
  def chapman(file)
    chapman = file.county
    return chapman if  ChapmanCode.value?(chapman)
    return ChapmanCode.value_at(chapman) if ChapmanCode.has_key?(chapman)
    register = get_register_object(file)
    church = get_church_object(register)
    place = get_place_object(church)
    chapman = place.chapman_code unless place.blank?
    chapman
  end
  def place_name(file)
    place_name = file.place
    if place_name.blank?
      register = get_register_object(file)
      church = get_church_object(register)
      place = get_place_object(church)
      place_name = place.place_name unless place.blank?
    end
    place_name
  end
  def get_register_object(file)
    register = file.register unless file.blank?
  end
  def get_church_object(register)
    church = register.church unless register.blank?
  end
  def get_place_object(church)
    place = church.place unless church.blank?
  end
  def uploaded_date(file)
    file.uploaded_date.strftime("%d %b %Y") unless file.uploaded_date.nil?
  end
  def file_name(file)
    file.file_name[0..-5]  unless file.file_name.nil?
  end
  def locked_by_transcriber(file)
    if file.locked_by_transcriber
      value = "Y"
    else
      value = "N"
    end
    value
  end
  def locked_by_coordinator(file)
    if file.locked_by_coordinator
      value = "Y"
    else
      value = "N"
    end
    value
  end
  def base_uploaded_date(file)
    file.base_uploaded_date.strftime("%d %b %Y") unless file.base_uploaded_date.nil?
  end

  def waiting_date(file)
    file.waiting_date.strftime("%d %b %Y") unless file.waiting_date.nil?
  end
  def errors(file)
    if file.error >= 0
      errors = file.error
    else
      errors = 0
    end
    errors
  end

end
