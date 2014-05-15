class Church
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  
  field :church_name,type: String
  field :last_amended, type: String
  field :denomination, type: String
  field :location, type: String

  field :church_notes, type: String
  has_many :registers, dependent: :restrict

   embeds_many :alternatechurchnames
   accepts_nested_attributes_for :alternatechurchnames

  belongs_to :place, index: true
  index({ place_id: 1, church_name: 1 }, { unique: true })
  validates_presence_of :church_name
  validate :church_does_not_exist, on: :create
  

   def church_does_not_exist 
  
   
     # errors.add(:church_name, "already exits") unless place.nil?

  end 


  def self.find_by_name_and_place(chapman_code, place_name,church_name)
    #see if church exists
   my_place = Place.where(:chapman_code => chapman_code, :place_name => place_name).first
    if my_place
      my_place_id = my_place[:_id]
      my_church = Church.where(:place_id => my_place_id, :church_name => church_name).first
    else
      my_church = nil
    end
    
    return my_church
  
  end

  def self.create_or_update_last_amended_date(freereg_file)
    register = freereg_file.register._id
    register = Register.find(register)
    church = register.church.id
    church = Church.find(church)
    original_last_amended_date = church.last_amended
    file_amended_date = freereg_file.modification_date
    file_creation_date = freereg_file.transcription_date
    new_last_amended_date = freereg_file.modification_date
    new_last_amended_date = file_creation_date if (Freereg1CsvFile.convert_date(freereg_file.transcription_date) > Freereg1CsvFile.convert_date(freereg_file.modification_date))
    new_last_amended_date = original_last_amended_date if (Freereg1CsvFile.convert_date(original_last_amended_date ) > Freereg1CsvFile.convert_date(new_last_amended_date))
    church.last_amended = new_last_amended_date
    church.save
    place = church.place
    my_place_date = place.last_amended
    place.last_amended = church.last_amended if (my_place_date.nil? ||(Freereg1CsvFile.convert_date(church.last_amended ) > Freereg1CsvFile.convert_date(my_place_date)))
    place.save
  end 
  
  def self.merge(churches)
     churches_names = Array.new
        
          if churches.length >1 then

               churches.each do |church|
                 churches_names << church.church_name
               end # number of churches do
         
               duplicate_churches = churches_names.select{|element| churches_names.count(element) > 1 }
               duplicate_church_names = duplicate_churches.uniq
        
                  if duplicate_churches.length >= 1 then
                    #have duplicate church asume there is only one duplicate
                     duplicate_church_names.each do |duplicate_church_name|

                       first_church = churches[churches_names.index(duplicate_church_name)]
                       second_church = churches[churches_names.rindex(duplicate_church_name)]
                       second_church_registers =  second_church.registers
                         second_church_registers.each do |reg|
                            first_church.registers << reg
                         end # reg do
              
                 first_church.save
                 second_church.save

        #we now need to merge registers within the church
            
                  registers = first_church.registers
                
                  if  registers.length > 1
                    register_names = Array.new
                      registers.each do |register|
                         register_names << register.alternate_register_name
                      end #register do

                    duplicate_registers = register_names.select{|element| register_names.count(element) > 1 }
                    duplicate_register_names = duplicate_registers.uniq
                 
                      if duplicate_registers.length >= 1 then
                          duplicate_register_names.each do |duplicate_register_name|

                            first_register = registers[register_names.index(duplicate_register_name)]
                            second_register = registers[register_names.rindex(duplicate_register_name)]
                            second_register_files =  second_register.freereg1_csv_files
                               second_register_files.each do |file|
                                   first_register.freereg1_csv_files << file

                               end # file do

                       # first_register.save
                           second_register.delete 
                          end #duplicate register do
                      end # duplicate_registers.length
                  
                    second_church.delete 

                  end #no registers to merge

               end # duplicate church name

        end # no duplicate churches
               
      end #only one church
  end

end
