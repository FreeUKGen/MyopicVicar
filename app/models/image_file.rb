# Copyright 2012 Trustees of FreeBMD
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 
class ImageFile
  require 'RMagick'
  include Mongoid::Document
  include Mongoid::Timestamps

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
  
  # filename
  field :name, type: String

  # location of original file to be used when derivation happens
  field :original_name, type: String

  #
  # TODO consider whether or not we actually need this
  #
  field :path, type: String
  
  field :width, type: Integer
  field :height, type: Integer

  field :thumbnail_width, type: Integer
  field :thumbnail_height, type: Integer

  def display_name
    File.basename(self.name)
  end
  
  def original?
    self.original_name.nil?    
  end
  
 
  
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
    log "initialize_image called on #{self.name} by #{caller[0]}"
    log "initialize_image loading file #{self.class.absolutize(self.name)}"
    image= Magick::ImageList.new(self.class.absolutize(self.name))    
    self.width = image.columns
    self.height = image.rows
    log "initialize_image recording [x,y]=[#{self.width},#{self.height}]"
    make_thumbnail(image)    
  end

  
  THUMB_HEIGHT = 120
  def make_thumbnail(image)
    # figure out dimensions, but make sure they're proportional
    thumb_width = ((THUMB_HEIGHT.to_f / self.height.to_f ) * self.width).to_i
    thumb_image = image.thumbnail(thumb_width, THUMB_HEIGHT)
    log "make_thumbnail writing thumbnail to "+ImageFile.absolutize(thumbnail_name)
    thumb_image.write(ImageFile.absolutize(thumbnail_name))
    self.thumbnail_width = thumb_width
    self.thumbnail_height = THUMB_HEIGHT
  end
  

  
  def image_url
    # returns a relative path to the image file
    self.name.gsub(/\.\/public\/assets\//, "/")
  end
  
  def thumbnail_url
    # returns a relative path to the thumbnail file
    self.thumbnail_name.gsub(/\.\/public\/assets\//, "/")
  end

  def file_directory
    File.dirname(self.name)
  end

  def filename_stub
    ext = File.extname(self.name)
    File.basename(self.name, ext)
  end

  def thumbnail_name
    File.join(file_directory.sub(Upload::ORIGINALS_DIR, Upload::DERIVATION_DIR), "#{filename_stub}_thumb#{PNG_SUFFIX}")
  end
  
  def log(msg)
    self.image_dir.log(msg) unless self.image_dir.nil?
  end

  def rotate(degrees)
    log("rotate(#{degrees}) called on #{self.name}")
    log("rotate(#{degrees}) saving original")
    save_original
    log("rotate(#{degrees}) reading #{self.name}")
    image=Magick::ImageList.new(self.class.absolutize(self.name))        
    log("rotate(#{degrees}) rotating")
    image.rotate!(degrees)
    image.write(self.class.absolutize(self.name))
    log("rotate(#{degrees}) re-initializing")
    initialize_image
    save!
  end

  # TODO: rewrite the image manipulation methods to do something clever with blocks instead
  # of all the repetition
  def negate
    save_original
    image=Magick::ImageList.new(self.class.absolutize(self.name))        
    image=image.negate
    image.write(self.class.absolutize(self.name))
    initialize_image
    save!
  end

  def deskew
    log("deskew called on #{self.name}")
    log("deskew saving original")
    save_original
    log("deskew reading #{self.name}")
    image=Magick::ImageList.new(self.class.absolutize(self.name))        
    log("deskew deskewing")
    image = image.deskew
    image.write(self.class.absolutize(self.name))
    log("deskew re-initializing")
    initialize_image
    save!
  end
  
  def revert
    unless self.original?
      # delete the working files
      File.delete(self.name)
      # point at the original files
      self.name = self.original_name
      self.original_name = nil
    end
    save!
  end
  
  def save_original
    if self.original?
      # first hide the original
      self.original_name = self.name
      self.save!
      # now move the working image to the derived directory
      self.name = self.original_name.sub(Upload::ORIGINALS_DIR, Upload::DERIVATION_DIR)
      FileUtils::cp(self.original_name, self.name)
    end
  end
  
end
