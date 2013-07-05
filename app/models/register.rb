class Register
  include Mongoid::Document
  
  field :status, type: String
  field :register_type, type: String
  field :record_types, type: Array
  field :user_id,  type: String
  field :start_year, type: Integer
  field :end_year, type: Integer
  field :transcribers, type: Array
  field :file_name, type: String
  has_one :freereg1_csv_file
  embedded_in :church
  
  
  def self.update_or_create_register(freereg1_csv_file)
    # find if register exists
    register = find(freereg1_csv_file.to_register)
    if register
     #update register
      register.update_attributes(freereg1_csv_file.to_register)
      register.church.place.save!
    else 
    # creatre the register   
     register = create_register_for_church(freereg1_csv_file.to_register)   
    end
  end

  def self.create_register_for_church(args)
    # look for the church
    church = Church.find_by_name_and_place(args[:chapman_code], args[:place_name],args[:church_name])
    if church
      # locate place
      place = args[:place_name]
    else
      #church does not exist so see if Place exists with another church
      place = Place.where('chapman_code' => args[:chapman_code], 'place_name' => args[:place_name]).first
      unless place
        #place does not exist so lets create new place first
        place = Place.new(:chapman_code => args[:chapman_code], :place_name => args[:place_name])   
      end
      #now create the church entry
      church = Church.new(:church_name => args[:church_name])
      place.churches << church
    end
    #now creat the register
    register = Register.new(args) 
    church.registers << register
    #and save everything
    register.church.place.save!
    register
  end


 
  
  def self.find(args)
    church = Church.find_by_name_and_place(args[:chapman_code], args[:place_name], args[:church_name])
    if church
      register = church.registers.detect do |r|
        r.user_id == args[:user_id] && r.file_name == args[:file_name]
      end
      register 
    else
      nil
    end
  end
end