class FreeregContent
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short

  require 'chapman_code'
  field :county, type: String#, :required => false
  field :chapman_codes,  type: Array, default: []
  validates_inclusion_of :county, :in => ChapmanCode::values+[nil]
  field :place, type: String
  field :church, type: String
  field :record_type, type: String#, :required => false
  validates_inclusion_of :record_type, :in => RecordType::ALL_TYPES+[nil]

def search
  Place.where(search_params).order_by(:place_name.asc).all
   
  end
def search_params
    params = Hash.new
    params[:chapman_code] = county if county
    params
  end
 def get_alternate_place_names
          @names = Array.new
          @alternate_place_names = self.alternateplacenames.all
          @alternate_place_names.each do |acn|
          name = acn.alternate_name
          @names << name
         end
         @names
  end
end
