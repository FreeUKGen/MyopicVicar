class EmendationType
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :target_field, type: String # actually a symbol 
  field :origin, type: String
  
  has_many :emendation_rules
  
  def target_field
    self[:target_field].to_sym
  end

  def target_field=(target_sym)
    self[:target_field] = target_sym.to_s
  end


  
end
