class Register
  include Mongoid::Document
  
  field :status, type: String
  field :register_type, type: String
  field :record_types, type: Array
  
  field :start_year, type: Integer
  field :end_year, type: Integer
  field :transcribers, type: Array
  field :file_name, type: String
  has_one :freereg1_csv_file
  embedded_in :church
  
  
  def self.update_or_create_register(freereg1_csv_file)
    # find by ID
    register = find(freereg1_csv_file.register_id)

    unless register
      # find by name
      register = find_by_name_and_years(freereg1_csv_file.to_register)
      # find church by name
      unless register
        register = create_register_for_church(freereg1_csv_file.to_register)
      end
      
    end
    # update document
    register.update_attributes(freereg1_csv_file.to_register)
     
    register.church.place.save!
  end

  def self.create_register_for_church(args)

    # look for the church
    church = Church.find_by_name_and_place(args[:chapman_code], args[:place_name],args[:church_name])
    
    # look for the place
    if church
      place = church.place
    else
      place = Place.where('chapman_code' => args[:chapman_code], 'place_name' => args[:place_name]).first
      
      unless place
        place = Place.new(:chapman_code => args[:chapman_code], :place_name => args[:place_name])
      end
      
      church = Church.new(:church_name => args[:church_name])
      place.churches << church
    end
    register = Register.new(args)
    
    church.registers << register
    
    register
  end


  # TODO add parish filters
  def self.find_by_name_and_years(args)
    church = Church.find_by_name(args[:chapman_code], args[:church_name])
    
    if church
      register = church.registers.detect do |r|
        r.start_year == args[:start_year] && r.end_year == args[:end_year]
      end
        
      register
    else
      nil
    end
  end
  
  def self.find(register_id)
    return nil unless register_id
    id = register_id.kind_of?(BSON::ObjectId) ? register_id : BSON::ObjectId.new(register_id)
    place = Place.where('churches.registers._id' => register_id).first
    if place
      church = place.churches.detect { |c| c.registers.any? { |r| r.id == register_id} }
      register = church.registers.detect { |r| r.id == register_id }
      
      register
    else
      nil
    end
  end
  
  
end