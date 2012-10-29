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


  validate :name_not_blank

  def search
    SearchRecord.all(search_params)
  end
  
  def search_params
    params = Hash.new
    params[:record_type] = record_type if record_type
    params[:chapman_code] = chapman_code if chapman_code
    if inclusive
      params['inclusive_names.first_name'] = first_name if first_name
      params['inclusive_names.last_name'] = last_name if last_name     
    else
      params['primary_names.first_name'] = first_name if first_name
      params['primary_names.last_name'] = last_name if last_name  
    end

    params
  end

  def name_not_blank
    if first_name.blank? && last_name.blank?
      errors.add(:last_name, "Both name fields cannot be blank.")
    end
  end
  
  
end
