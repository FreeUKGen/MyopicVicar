class SearchQuery
  include MongoMapper::Document

  require 'chapman_code'
  require 'name_role'
  # consider extracting this from entities
  
  key :first_name, String, :required => false
  key :last_name, String, :required => false
  key :fuzzy, Boolean
  key :role, String, :required => false, :in => NameRole::ALL_ROLES+[nil] # I'm not sure why in and required=>false seem incompatible; the +[nil] is a work-around
  key :record_type, String, :required => false, :in => RecordType::ALL_TYPES+[nil]
  key :chapman_code, String, :required => false, :in => ChapmanCode::values+[nil]
#  key :extern_ref, String
  key :inclusive, Boolean


  validate :name_not_blank

  def search
    SearchRecord.all(search_params)
  end
  
  def search_params
    params = Hash.new
    params[:record_type] = record_type if record_type
    params[:chapman_code] = chapman_code if chapman_code

    params.merge!(name_search_params)
    params
  end

  def name_search_params
    params = Hash.new
    name_params = Hash.new
    search_type = inclusive ? "inclusive" : "primary"

    if fuzzy
    
      name_params["first_name"] = Text::Soundex.soundex(first_name) if first_name     
      name_params["last_name"] = Text::Soundex.soundex(last_name) if last_name     

      params["#{search_type}_soundex"] =  { "$elemMatch" => name_params}
    else
      name_params["first_name"] = first_name.downcase if first_name
      name_params["last_name"] = last_name.downcase if last_name           

      params["#{search_type}_names"] =  { "$elemMatch" => name_params}
    end
    params
  end


  def name_not_blank
    if first_name.blank? && last_name.blank?
      errors.add(:last_name, "Both name fields cannot be blank.")
    end
  end
  
  
end
