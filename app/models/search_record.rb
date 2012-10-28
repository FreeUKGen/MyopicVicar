class SearchRecord
  include MongoMapper::Document
  SEARCHABLE_KEYS = [:first_name, :last_name]

  before_save :populate_inclusive_names

  
  # For the moment, this will merely mirror the Bicker 18c template

  key :first_name, String, :required => false
  key :last_name, String, :required => false
  
  key :father_first_name, String, :required => false
  key :father_last_name, String, :required => false

  key :mother_first_name, String, :required => false
  key :mother_last_name, String, :required => false

key :inclusive_names, Array, :require => false


  def populate_inclusive_names
    # primary names
    inclusive_names << { :first_name => first_name, :last_name => last_name }
    # father
    if father_first_name || father_last_name
      inclusive_names << { :first_name => father_first_name, :last_name => father_last_name }   
    end
    # mother
    if mother_first_name || mother_last_name
      inclusive_names << { :first_name => mother_first_name, :last_name => mother_last_name }   
    end
  end


end
