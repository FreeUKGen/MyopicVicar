class Church
  include Mongoid::Document
  
  field :church_name
  embeds_many :registers
  embedded_in :place
  
  def self.find_by_name(chapman_code, church_name)
    params = {}
    params["churches.church_name"] = church_name
    params["chapman_code"] = chapman_code
    place = Place.where(params).first

    # this may or may not contain our register
    if place
      church = place.churches.detect { |c| c.church_name = church_name }
    else
      nil
    end
  end

  def self.find_by_name_and_place(chapman_code, place_name,church_name)
    params = {}
    params["chapman_code"] = chapman_code
    params["place_name"] = place_name
    params["churches.church_name"] = church_name
    
    place = Place.all_of(params).first

    if place
     church = place.churches.detect { |c| c.church_name = church_name }
     return church
    else
      nil
    end
  
  end
end
