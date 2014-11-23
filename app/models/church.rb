class Church
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
   require 'register_type' 
  field :church_name,type: String
  field :last_amended, type: String
  field :denomination, type: String
  field :location, type: String
  field :place_name, type: String
  field :church_notes, type: String
  has_many :registers, dependent: :restrict

   embeds_many :alternatechurchnames
   accepts_nested_attributes_for :alternatechurchnames

  belongs_to :place, index: true
  index({ place_id: 1, church_name: 1 }, { unique: true })
  validates_presence_of :church_name
  validate :church_does_not_exist, on: :create
  
def church_does_not_exist 
     #errors.add(:church_name, "Church of that name already exits") unless place.church.nil?
end 


def self.find_by_name_and_place(chapman_code, place_name,church_name)
    #see if church exists
   my_place = Place.where(:chapman_code => chapman_code, :place_name => place_name,:disabled => "false").first
    if my_place
      my_place_id = my_place[:_id]
      my_church = Church.where(:place_id => my_place_id, :church_name => church_name).first
    else
      my_church = nil
    end
    return my_church
  
end  

def are_we_changing_location?(param)
  change = false
  change = true unless param[:church_name] ==  self.church_name
  change = true unless param[:place_name] == self.place.place_name
  change
end

def change_name(church_name,place_name)
   successful = true
   old_church_id = self._id
   old_place_id = self.place_id
   chapman_code = self.place.chapman_code
   place_name = self.place.place_name if place_name.nil?
   param = { :church_name => church_name, :place => place_name, :county => chapman_code }
    Church.relocate_with_no_registers(self,param) unless self.registers.exists?

     self.registers.each do |register|
       param[:register_type] = register.register_type 
       register.relocate_with_no_files(param) unless register.freereg1_csv_files.exists?
       register.freereg1_csv_files.each do |file|
         new_file = Freereg1CsvFile.update_location(file,param)
         successful = false if new_file.nil? 
       end #file
      end #register
    successful 
 end

 def self.relocate_with_no_registers(church,param)
   old_church = church
   old_place = church.place
   old_church_name = church.church_name
   new_place = Place.where(:chapman_code => param[:county],:place_name => param[:place],:disabled => 'false').first
   new_church = Church.where(:place_id =>  new_place._id, :church_name => param[:church_name]).first
  if  new_church.nil?
    new_church = Church.new(:place_id =>  new_place._id,:church_name => param[:church_name],:place_name => param[:place])  if  new_church.nil?
    new_church.save
    church = new_church
  else
    church.update_attributes(:place_id =>  new_place._id, :church_name => param[:church_name],:place_name => param[:place])
  end
    old_place.churches.where(:church_name => old_church_name).delete_all   unless old_church.registers.exists? || !old_church.has_no_input?
    new_place.save
    church
  end

 def has_no_input?
  value = true
  value = false if self.denomination.present? || self.church_notes.present? || self.location.present? 
  value 
 end
 def data_contents
  min = Time.new.year
     max = 1500
     records = 0
       self.registers.each do |register|
        register.freereg1_csv_files.each do |file|
          min = file.datemin.to_i if file.datemin.to_i < min
          max = file.datemax.to_i if file.datemax.to_i > max 
          records = records + file.records.to_i unless file.records.nil?
        end
       end
    stats =[records,min,max]
end 
end