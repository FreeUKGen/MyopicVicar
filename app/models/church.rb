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
end
