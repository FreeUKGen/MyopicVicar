class ImageFile
  require 'RMagick'
  include MongoMapper::Document         

  PNG_SUFFIX = '.png'

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
  before_save :initialize_image

# Attribute options extras ::::::::::::::::::::::::::::::::::::::::
# attr_accessible :first_name, :last_name, :email

# Validations
# key :name, :required =>  true      

# Defaults
# key :done, :default => false

# Typecast
# key :user_ids, Array, :typecast => 'ObjectId'
  
   
  key :name, String

  #
  # TODO consider whether or not we actually need this
  #
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
    image= Magick::ImageList.new(self.name)    
    self.width = image.columns
    self.height = image.rows
    make_thumbnail(image)    
#    save!
  end

  
  THUMB_HEIGHT = 120
  def make_thumbnail(image)
    # figure out dimensions, but make sure they're proportional
    thumb_width = ((THUMB_HEIGHT.to_f / self.height.to_f ) * self.width).to_i
    thumb_image = image.thumbnail(thumb_width, THUMB_HEIGHT)
    thumb_image.write(fq(thumbnail_name))
  end
  

  
  def image_url
    # returns a relative path to the image file
  end
  
  def thumbnail_url
    # returns a relative path to the thumbnail file
  end

  def file_directory
    File.dirname(self.name)
  end

  def fq(filename)
    # make sure the full path is correct
    File.join(File.dirname(self.name), File.basename(filename))
  end

  def filename_stub
    ext = File.extname(self.name)
    File.basename(self.name, ext)
  end

  def thumbnail_name
    "#{filename_stub}_thumb#{PNG_SUFFIX}"
  end
  
end
