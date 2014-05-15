class EmendationType
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :target_field, type: String # actually a symbol 
  field :origin, type: String
  
  has_many :emendation_rules
  index({ name: 1, target_field: 1, origin: 1})
  index({ target_field: 1, origin: 1})
  index({ origin: 1})
  def target_field
    self[:target_field].to_sym
  end

  def target_field=(target_sym)
    self[:target_field] = target_sym.to_s
  end


  
end
