class ImageUpload
  include MongoMapper::Document         

  validates_presence_of :path
  validate :source_path_is_valid

# Validations :::::::::::::::::::::::::::::::::::::::::::::::::::::
# validates_presence_of :attribute

# Assocations :::::::::::::::::::::::::::::::::::::::::::::::::::::
# belongs_to :model
# many :model
# one :model

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
  
  
  
  
  def source_path_is_valid
    path = self[:path]
    if path
      unless File.exists?(path)
        errors.add(:path, "Path #{path} must be a directory on the server.  It appears not to exist.")       
      end
      unless File.directory?(path)
        errors.add(:path, "Path #{path} must be a directory on the server.  It appears not to be a directory.")       
      end
      unless File.executable?(path)
        errors.add(:path, "Path #{path} must be an executable directory on the server.  It appears not to be executable by this program, so we cannot change directories to it.")       
      end
      unless File.readable?(path)
        errors.add(:path, "Path #{path} must be a readable directory on the server.  It appears not to be readable by this program, so we cannot list files in it.")       
      end
      
      
      
    end
  end
  
  
end