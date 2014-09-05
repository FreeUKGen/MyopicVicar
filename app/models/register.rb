class Register
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  require 'record_type'
  require 'register_type' 

  field :status, type: String
  field :register_name,  type: String
  field :alternate_register_name,  type: String
  field :register_type,  type: String
  field :quality,  type: String
  field :source,  type: String
  field :copyright,  type: String
  field :register_notes,  type: String
  field :last_amended, type: String
  
  has_many :freereg1_csv_files, dependent: :restrict
  belongs_to :church, index: true

 
  index({ church_id: 1, register_name: 1}, { unique: true })
  index({ register_name: 1})
  index({ alternate_register_name: 1})
   index({ church_id: 1, alternate_register_name: 1}, { unique: true })
   

 
 
  def self.update_or_create_register(freereg1_csv_file)
    # find if register exists
   register = find_register(freereg1_csv_file.to_register)
    if register
      #update register
      register.freereg1_csv_files << freereg1_csv_file
      #freereg1_csv_file.save
    else 
    # create the register 
      register = create_register_for_church(freereg1_csv_file.to_register, freereg1_csv_file)   
    end
  end

  def self.create_register_for_church(args,freereg1_csv_file)
    # look for the church
     if @@my_church
     # locate place
     my_place = @@my_church.place
     
    else
      #church does not exist so see if Place exists 
      my_place = Place.where(:chapman_code => args[:chapman_code], :place_name => args[:place_name],:disabled => 'false').first
     unless my_place
       #place does not exist so lets create new place first
       my_place = Place.new(:chapman_code => args[:chapman_code], :place_name => args[:place_name], :disabled => 'false', :grid_reference => 'TQ336805') 
      
       my_place.error_flag = "Place name is not approved" 
     end
      #now create the church entry
      @@my_church = Church.new(:church_name => args[:church_name])
      my_place.churches << @@my_church
    end
    #now create the register
    register = Register.new(args) 
    register.freereg1_csv_files << freereg1_csv_file
 
    @@my_church.registers << register
    @@my_church.save
    #and save everything
 
    my_place.data_present = true
   
    my_place.save!
    #freereg1_csv_file.save
    register
  end


 
  
  def self.find_register(args)
    
    @@my_church = Church.find_by_name_and_place(args[:chapman_code], args[:place_name], args[:church_name])
    if @@my_church
     
      my_church_id = @@my_church[:_id]
      register = Register.where(:church_id =>my_church_id, :alternate_register_name=> args[:alternate_register_name] ).first
      unless register then
      
        register = Register.where(:church_id =>my_church_id, :register_name=> args[:alternate_register_name] ).first
        unless register
          register = nil
        end
       end
    else
      register = nil
    end
     register 
  end

  def self.clean_empty_registers(register)
    p "cleaning"
    #clean out empty register/church/places 
    unless register.freereg1_csv_files.exists?
      church = register.church
      place = church.place 
      church.registers.where(:alternate_register_name => register.alternate_register_name).delete_all if place.error_flag == "Place name is not approved" || register.has_no_input?
      place.churches.where(:church_name => church.church_name).delete_all if !church.registers.exists? && church.has_no_input?
      place.update_attributes(:data_present => false) unless place.search_records.exists?
      place.destroy if !place.search_records.exists? && place.error_flag == "Place name is not approved"
    end
  end

def old_location
  old_register = self
  old_church = self.church
  old_place = old_church.place
  location = {:register => old_register , :church => old_church, :place => old_place}
end

def new_location(param)
  new_place = Place.where(:chapman_code => param[:county],:place_name => param[:place],:disabled => 'false').first
  new_church = Church.where(:place_id =>  new_place._id, :church_name => param[:church_name]).first
  if  new_church.nil?
    new_church = Church.new(:place_id =>  new_place._id,:church_name => param[:church_name],:place_name => param[:place])  if  new_church.nil?
    new_church.save
  end
  number_of_registers = new_church.registers.count
  new_alternate_register_name = param[:church_name].to_s + ' ' + param[:register_type].to_s
  p  number_of_registers
  if number_of_registers == 0
    new_register = Register.new(:church_id => new_church._id,:alternate_register_name => new_alternate_register_name, :register_type => param[:register_type])
    
  else
    if Register.where(:church_id => new_church._id,:alternate_register_name => new_alternate_register_name, :register_type => param[:register_type]).count == 0
      new_register = Register.new(:church_id => new_church._id,:alternate_register_name => new_alternate_register_name, :register_type =>param[:register_type])
     
    else 
      new_register = Register.where(:church_id => new_church._id, :alternate_register_name => new_alternate_register_name, :register_type => param[:register_type]).first
     
    end
    new_register.save
  end
  location = {:register => new_register, :church => new_church, :place => new_place}
end

  def relocate_with_no_files(param)
    p "register has no files"
   old_location = self.old_location
   p old_location
   param[:county] = old_location[:place].chapman_code if param[:county].nil? || param[:county].empty?
   new_location = self.new_location(param)
    p new_location
   new_location[:church].save(:validate => false) unless old_location[:church] == new_location[:church]
   new_location[:place].save(:validate => false) unless old_location[:place] == new_location[:place] 
   old_location[:church].registers.where(:_id => old_location[:register]._id).delete_all unless old_location[:register] == new_location[:register] 
   #remove old church if there are no more registers
   old_location[:place].churches.where(:church_name => old_location[:church].church_name).delete_all   unless old_location[:church].registers.exists? || !old_location[:church].has_no_input?
   new_location[:register]
  end

 def self.change_type(register,type)
   param = Hash.new
   old_location = register.old_location
   param[:register_type] = type
   param[:church_name] = old_location[:church].church_name
   param[:place] = old_location[:place].place_name
   param[:county] = old_location[:place].chapman_code
   new_location = register.new_location(param)
    register.freereg1_csv_files.each do |file|
        file.update_attributes(:register_id => new_location[:register]._id,:register_type => type) 
        param[:new_file_id] = file._id
        file.update_entries_and_search_records(param)
    end #file
  new_location[:register].save(:validate => false) unless old_location[:register] == new_location[:register]
  new_location[:church].save(:validate => false) unless old_location[:church] == new_location[:church]
  new_location[:place].save(:validate => false) unless old_location[:place] == new_location[:place] 
  Register.clean_empty_registers(old_location[:register]) unless old_location[:register] == new_location[:register] 
  new_location[:register]
 end

 def has_no_input?
 value = true
 value = false if self.status.present? || self.quality.present? || self.source.present? || self.copyright.present?|| self.register_notes.present?
 value 
 end
 
end