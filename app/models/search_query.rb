class SearchQuery
  include Mongoid::Document

  require 'chapman_code'
  require 'name_role'
  require 'date_parser'
  # consider extracting this from entities
  
  field :first_name, type: String#, :required => false
  field :last_name, type: String#, :required => false
  field :fuzzy, type: Boolean
  field :role, type: String#, :required => false
  validates_inclusion_of :role, :in => NameRole::ALL_ROLES+[nil]
  field :record_type, type: String#, :required => false
  validates_inclusion_of :record_type, :in => RecordType::ALL_TYPES+[nil]
  field :chapman_codes, type: Array, default: []#, :required => false
#  validates_inclusion_of :chapman_codes, :in => ChapmanCode::values+[nil]
  #field :extern_ref, type: String
  field :inclusive, type: Boolean
  field :start_year, type: Integer
  field :end_year, type: Integer
  has_and_belongs_to_many :places, inverse_of: nil
  field :place_radius, type: Integer
  field :place_system, type: String
  validates_inclusion_of :place_system, :in => Place::MeasurementSystem::ALL_SYSTEMS+[nil]  

  belongs_to :userid_detail
  
  validate :name_not_blank
  validate :radius_is_valid
  before_save :clean_blanks

  def search
    SearchRecord.where(search_params).asc(:search_date).all
  end
  
  def search_params
    params = Hash.new
    params[:record_type] = record_type if record_type
    params.merge!(place_search_params)
    params.merge!(date_search_params)
    params.merge!(name_search_params)

    params
  end

  def place_search_params
    params = Hash.new
    if place_search?
      search_place_ids = radius_place_ids
      params[:place_id] = { "$in" => search_place_ids }
    else
      params[:chapman_code] = { '$in' => chapman_codes } if chapman_codes && chapman_codes.size > 0
    end
        
    params
  end

  def place_search?
    place_ids && place_ids.size > 0
  end
  
  def radius_place_ids
    radius_ids = []
    all_radius_places.map { |place| radius_ids << place.id }
    radius_ids.concat(place_ids)
    radius_ids.uniq
  end


  def date_search_params
    params = Hash.new
    if start_year || end_year
      date_params = Hash.new
      date_params["$gt"] = DateParser::start_search_date(start_year) if start_year
      date_params["$lt"] = DateParser::end_search_date(end_year) if end_year
      params[:search_date] = date_params
    end
    params
  end
  

  def name_search_params
    params = Hash.new
    name_params = Hash.new
    search_type = inclusive ? { "$in" => [SearchRecord::PersonType::FAMILY, SearchRecord::PersonType::PRIMARY ] } : SearchRecord::PersonType::PRIMARY
    name_params["type"] = search_type

    if fuzzy
    
      name_params["first_name"] = Text::Soundex.soundex(first_name) if first_name     
      name_params["last_name"] = Text::Soundex.soundex(last_name) if last_name     

      params["search_soundex"] =  { "$elemMatch" => name_params}
    else
      name_params["first_name"] = first_name.downcase if first_name
      name_params["last_name"] = last_name.downcase if last_name           

      params["search_names"] =  { "$elemMatch" => name_params}
    end
    params
  end


  def name_not_blank
    if first_name.blank? && last_name.blank?
      errors.add(:last_name, "Both name fields cannot be blank.")
    end
  end

  def radius_is_valid
    if !place_radius.blank? && places.size < 1
      errors.add(:place_radius, "You must choose a place to perform a radius search.")
    end
  end

  def clean_blanks
    chapman_codes.delete_if { |x| x.blank? }
  end  

  def radius_search?
    place_radius && place_radius > 0
  end

  def all_radius_places
    all_places = []
    place_ids.each do |place_id|
      if radius_search?
        radius_places(place_id).each do |near_place|
          all_places << near_place
        end
      end
    end
    all_places.uniq
  end



  def radius_places(place_id)
    place = Place.find(place_id)
    place.places_near(place_radius, place_system)    
  end
  
end
