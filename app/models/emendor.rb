class Emendor
  include MongoMapper::Document

  module EmendationTypes
    ANGLICIZATION = 'anglicization'
    CAMBRICIZATION = 'cambricization'
    EXPANSION = 'expansion'
    MODERNIZATION = 'modernization'
    
    ALL=[ANGLICIZATION,CAMBRICIZATION,EXPANSION,MODERNIZATION]
  end

  module TargetFields
    FIRST_NAME = :first_name
    LAST_NAME = :last_name
    ABODE = :abode
    
    ALL=[FIRST_NAME,LAST_NAME,ABODE]
  end

  key :type, String, :in => EmendationTypes::ALL
  key :target, String, :in => TargetFields::ALL   #consider changing this to an Array
  key :replacements, Hash
  
  def emend(name)
    source = name[target]

    source = source.gsub(/\W/, '') #eliminate non-word characters
    
    emendation = replacements[source]
    if emendation
      name.merge({target => emendation})
    else
      nil
    end
  end

  def target
    self[:target].to_sym
  end

  def target=(target_sym)
    self[:target] = target_sym.to_s
  end

end
