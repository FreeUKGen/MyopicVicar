class ImageFile
  require 'RMagick'
  include MongoMapper::Document         

# Validations :::::::::::::::::::::::::::::::::::::::::::::::::::::
# validates_presence_of :attribute

# Assocations :::::::::::::::::::::::::::::::::::::::::::::::::::::
# belongs_to :model
# many :model
# one :model
  belongs_to :image_dir


# Callbacks ::::::::::::::::::::::::::::::::::::::::::::::::::::::: 
# before_create :your_model_method
# after_create :your_model_method
# before_update :your_model_method 
#  before_save :initialize_image

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
  
  key :width, Integer
  key :height, Integer
  

  def self.is_image?(filename)
    begin
      image_list = Magick::ImageList.new(filename)
      unless image_list.size == 1
        return false
      end
    rescue Magick::ImageMagickError
      return false
    end
    # if we got this far we didn't hit any of the error conditions
    true
  end


  # load up the image and initialize its metadata
  def initialize_image
    
    
  end
  

  
  def image_url
    # returns a relative path to the image file
  end
  
  def thumbnail_url
    # returns a relative path to the thumbnail file
  end
  
end
