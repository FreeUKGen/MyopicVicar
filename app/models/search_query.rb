class SearchQuery
  require 'chapman_code'
  # consider extracting this from entities
  RECORD_TYPES = ['Baptism', 'Marriage', 'Burial']
  ROLES = ['Father', 'Mother', 'Son', 'Daughter', 'Groom', 'Bride']
  
  include MongoMapper::Document
  key :first_name, String, :required => false
  key :last_name, String, :required => false
  key :fuzzy, Boolean
  key :role, String, :required => false, :in => ROLES+[nil] # I'm not sure why in and required=>false seem incompatible; the +[nil] is a work-around
  key :record_type, String, :required => false, :in => RECORD_TYPES+[nil]
  key :chapman_code, String, :required => false, :in => ChapmanCode::values+[nil]
#  key :extern_ref, String
  key :inclusive, Boolean


  def search
    SearchRecord.all(search_params)
  end
  
  def search_params
    params = Hash.new
    params[:first_name] = first_name if first_name
    params[:last_name] = last_name if last_name
    params[:chapman_code] = chapman_code if chapman_code
    params
  end
  
end
