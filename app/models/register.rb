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
  belongs_to :church
  index({ church_id: 1, user_id: 1, file_name: 1 }, { unique: true })
  
  def self.update_or_create_register(freereg1_csv_file)
    # find if register exists
   register = find_register(freereg1_csv_file.to_register)
    if register
     #update register
      register.update_attributes(freereg1_csv_file.to_register)
      register.save!
    else 
    # creatre the register  
     register = create_register_for_church(freereg1_csv_file.to_register)   
    end
  end

  def self.create_register_for_church(args)
    # look for the church
    if @my_church
     # locate place
     my_place = @my_church.place
    else
      #church does not exist so see if Place exists with another church
      my_place = Place.where('chapman_code' => args[:chapman_code], 'place_name' => args[:place_name]).first
      unless my_place
        #place does not exist so lets create new place first
       my_place = Place.new(:chapman_code => args[:chapman_code], :place_name => args[:place_name]) 
    end
      #now create the church entry
      @my_church = Church.new(:church_name => args[:church_name])
      my_place.churches << @my_church
    end
    #now creat the register
    register = Register.new(args) 
    @my_church.registers << register
    #and save everything
    @my_church.save!
    my_place.save!
    register.save!
    register
  end


 
  
  def self.find_register(args)
    @my_church = Church.find_by_name_and_place(args[:chapman_code], args[:place_name], args[:church_name])
    if @my_church
      my_church_id = @my_church[:_id]
      register = Register.all_of(:church_id =>my_church_id, :user_id => args[:user_id],:file_name => args[:file_name]).first
    else
      nil
    end
     register 
  end
end