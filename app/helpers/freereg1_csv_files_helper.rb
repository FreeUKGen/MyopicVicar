module Freereg1CsvFilesHelper

  def get_place(county,name)
    place = Place.where(:chapman_code => county, :place_name => name).first
  end
  def church_name(file)
    register = get_register_object(file)
    church = get_church_object(register)
    church_name = church.church_name unless church.blank?
  end
  def register_type(file)
    register = get_register_object(file)
    register_type = RegisterType.display_name(register.register_type) unless register.blank?
  end
  def county_name(file)
    register = get_register_object(file)
    church = get_church_object(register)
    place = get_place_object(church) 
    county_name = place.county unless place.blank?
  end
  def chapman(file)
    register = get_register_object(file)
    church = get_church_object(register)
    place = get_place_object(church) 
    place_name = place.chapman_code unless place.blank?
  end
  def place_name(file)
    register = get_register_object(file)
    church = get_church_object(register)
    place = get_place_object(church) 
    place_name = place.place_name unless place.blank?
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






end
