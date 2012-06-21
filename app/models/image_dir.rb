class ImageDir
  include MongoMapper::Document         

# Validations :::::::::::::::::::::::::::::::::::::::::::::::::::::
# validates_presence_of :attribute

# Assocations :::::::::::::::::::::::::::::::::::::::::::::::::::::
# belongs_to :model
# many :model
# one :model

  belongs_to :image_upload
  many :image_file

# Callbacks ::::::::::::::::::::::::::::::::::::::::::::::::::::::: 
# before_create :your_model_method
# after_create :your_model_method
# before_update :your_model_method 

# Attribute options extras ::::::::::::::::::::::::::::::::::::::::
# attr_accessible :first_name, :last_name, :email

# Validations
# key :name, :required =>  true      

# Defaults
# key :done, :default => false

# Typecast
# key :user_ids, Array, :typecast => 'ObjectId'
  
   
  key :name, String
  key :path, String
  timestamps!
  
  def convert_to_image_list
    il = ImageList.create(:name => self.name, :chapman_code => nil)
    il.image_files = self.image_file
    il.save!
    il
  end
  
  
  def log(msg)
    self.image_upload.log(msg)
  end
end
