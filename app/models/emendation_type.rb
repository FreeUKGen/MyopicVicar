class EmendationType
  include MongoMapper::Document
  key :name, String
  key :target_field, String # actually a symbol 
  timestamps!
  
  many :emendation_rules
  
  def target_field
    self[:target_field].to_sym
  end

  def target_field=(target_sym)
    self[:target_field] = target_sym.to_s
  end


  
end
