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
  before_save :relativize_paths

# Attribute options extras ::::::::::::::::::::::::::::::::::::::::
# attr_accessible :first_name, :last_name, :email

# Validations
# key :name, :required =>  true      

# Defaults
# key :done, :default => false

# Typecast
# key :user_ids, Array, :typecast => 'ObjectId'
  
  # should be pretty name
  key :name, String

  #
  # TODO consider whether or not we actually need this
  #
  key :path, String
  
  key :width, Integer
  key :height, Integer
  
 
  
  # always, always, always save relative paths
  def relativize_paths
    path &&= self.class.relativize(path)
    name &&= self.class.relativize(name)
  end

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

  def self.extract_pdf(filename, destination)
    FileUtils.mkdir(destination) unless File.exists?(destination)
    image_list = Magick::ImageList.new(filename)
    image_list.each_with_index do |image, i|
      image.write(File.join(destination, "#{i}.png"))
    end
  end


  def self.relativize(filename)
    # extract RAILS_ROOT from this
    filename.sub(Rails.root.to_s+File::SEPARATOR,"")
  end
  
  def self.absolutize(filename)
    if Pathname.new(filename).absolute?
      filename
    else
      # prepend RAILS_ROOT
      File.join(Rails.root.to_s, filename)      
    end
  end

  # load up the image and initialize its metadata
  def initialize_image
    log "initialize_image called on #{self.name}"
    log "initialize_image loading file #{self.class.absolutize(self.name)}"
    image= Magick::ImageList.new(self.class.absolutize(self.name))    
    self.width = image.columns
    self.height = image.rows
    make_thumbnail(image)    
  end

  
  THUMB_HEIGHT = 120
  def make_thumbnail(image)
    # figure out dimensions, but make sure they're proportional
    thumb_width = ((THUMB_HEIGHT.to_f / self.height.to_f ) * self.width).to_i
    thumb_image = image.thumbnail(thumb_width, THUMB_HEIGHT)
    log "Writing thumbnail to "+ImageFile.absolutize(thumbnail_name)
    thumb_image.write(ImageFile.absolutize(thumbnail_name))
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

  def filename_stub
    ext = File.extname(self.name)
    File.basename(self.name, ext)
  end

  def thumbnail_name
    File.join(file_directory.sub(ImageUpload::ORIGINALS_DIR, ImageUpload::DERIVATION_DIR), "#{filename_stub}_thumb#{PNG_SUFFIX}")
  end
  
  def log(msg)
    self.image_dir.log(msg) unless self.image_dir.nil?
  end
  
end
