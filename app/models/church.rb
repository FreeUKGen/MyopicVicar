class Church
  include Mongoid::Document
  
  field :church_name
  has_many :registers
  belongs_to :place
  index({ place_id: 1, church_name: 1 }, { unique: true })

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
end
