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
  field :chapman_codes, type: Array#, :required => false
#  validates_inclusion_of :chapman_codes, :in => ChapmanCode::values+[nil]
  #field :extern_ref, type: String
  field :inclusive, type: Boolean
  field :start_year, type: Integer
  field :end_year, type: Integer
  has_and_belongs_to_many :places, inverse_of: nil


  validate :name_not_blank

  def search
    SearchRecord.where(search_params).asc(:search_date).all
  end
  
  def search_params
    params = Hash.new
    params[:record_type] = record_type if record_type
    params[:chapman_code] = { '$in' => chapman_codes } if chapman_codes && chapman_codes.size > 0
    params.merge!(place_search_params)
    params.merge!(date_search_params)
    params.merge!(name_search_params)

    params
  end

  def place_search_params
    params = Hash.new
    if place_ids && place_ids.size > 0
      params[:place_id] = { "$in" => place_ids }
    end
        
    params
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
  
  
end
