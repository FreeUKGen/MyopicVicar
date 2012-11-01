class SearchRecord
  include MongoMapper::Document
  SEARCHABLE_KEYS = [:first_name, :last_name]

  before_save :transform

  module Source
    TRANSCRIPT='t'
    EMENDOR='e'
    USER_ADDITION='u'
  end

  module Role
    FATHER='f'
    MOTHER='m'
    HUSBAND='h'
    WIFE='w'
    GROOM='g'
    BRIDE='b'
    
    PRIMARY='p'
    
  end


  # transcript fields  
  key :first_name, String, :required => false
  key :last_name, String, :required => false
  
  key :father_first_name, String, :required => false
  key :father_last_name, String, :required => false

  key :mother_first_name, String, :required => false
  key :mother_last_name, String, :required => false

  key :husband_first_name, String, :required => false
  key :husband_last_name, String, :required => false

  key :wife_first_name, String, :required => false
  key :wife_last_name, String, :required => false

  key :groom_first_name, String, :required => false
  key :groom_last_name, String, :required => false

  key :bride_first_name, String, :required => false
  key :bride_last_name, String, :required => false


  # search fields
  key :primary_names, Array, :require => false
  key :inclusive_names, Array, :require => false
  # derived search fields
  key :primary_soundex, Array, :require => false
  key :inclusive_soundex, Array, :require => false


  def transform
    populate_search_from_transcript
    
    downcase_all
    #emend
    create_soundex    
  end

  def populate_search_from_transcript
    populate_primary_names
    populate_inclusive_names

  end

  
  def create_soundex
    primary_names.each do |name|
      primary_soundex << soundex_name_pair(name)
    end
    inclusive_names.each do |name|
      inclusive_soundex << soundex_name_pair(name)

    end
    
  end
  
  def soundex_name_pair(name)
    return { 
        :first_name => Text::Soundex.soundex(name[:first_name]), 
        :last_name => Text::Soundex.soundex(name[:last_name]) 
    }
  end
  
  def downcase_all
    primary_names.each do |name|
      name[:first_name].downcase!
      name[:last_name].downcase!
    end
    inclusive_names.each do |name|
      name[:first_name].downcase! if name[:first_name] 
      name[:last_name].downcase! if name[:last_name]
    end
  end

  def populate_primary_names
    # standard names
    primary_names << { :first_name => first_name, :last_name => last_name, :source => 'transcript' } unless first_name.blank? && last_name.blank?
    # marriage names
    primary_names << { :first_name => groom_first_name, :last_name => groom_last_name } unless groom_first_name.blank? && groom_last_name.blank?
    primary_names << { :first_name => bride_first_name, :last_name => bride_last_name } unless bride_first_name.blank? && bride_last_name.blank?
  end



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
    # husband
    if husband_first_name || husband_last_name
      inclusive_names << { :first_name => husband_first_name, :last_name => husband_last_name }   
    end
    # wife
    if wife_first_name || wife_last_name
      inclusive_names << { :first_name => wife_first_name, :last_name => wife_last_name }   
    end
    # groom
    if groom_first_name || groom_last_name
      inclusive_names << { :first_name => groom_first_name, :last_name => groom_last_name }   
    end
    # bride
    if bride_first_name || bride_last_name
      inclusive_names << { :first_name => bride_first_name, :last_name => bride_last_name }   
    end
  end


end
