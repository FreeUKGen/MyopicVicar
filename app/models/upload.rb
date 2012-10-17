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
class Upload
  require 'zip/zip'
  include MongoMapper::Document         
  
  validates_presence_of :upload_path
  validate :source_path_is_valid
  
  # Validations :::::::::::::::::::::::::::::::::::::::::::::::::::::
  # validates_presence_of :attribute
  
  # Assocations :::::::::::::::::::::::::::::::::::::::::::::::::::::
  # belongs_to :model
  # many :model
  # one :model
  many :image_dir
  many :image_upload_log
  
  
  # Callbacks ::::::::::::::::::::::::::::::::::::::::::::::::::::::: 
  # before_create :your_model_method
  # after_create :your_model_method
  # before_update :your_model_method 
  
  after_create :initialize_logfile
  
  
  # Attribute options extras ::::::::::::::::::::::::::::::::::::::::
  # attr_accessible :first_name, :last_name, :email
  
  # Validations
  # key :name, :required =>  true      
  
  # Defaults
  # key :done, :default => false
  
  # Typecast
  # key :user_ids, Array, :typecast => 'ObjectId'
  
  
  # we should only store the absolute path of the upload directory
  # the working and derivation directories should be relative paths from RAILS_ROOT (which is also the cwd of the rails app)
  # consider having each file record its path
  
  key :name, String
  key :upload_path, String
  
  key :working_dir, String
  key :originals_dir, String
  key :derivation_dir, String
  
  module Status
    NEW="new"
    PROCESSING="processing"
    READY="ready"
  end
  
  key :status, String, :default => Status::NEW
  
  timestamps!
  
  ORIGINALS_DIR='originals'
  DERIVATION_DIR='derived'
  ZIP_EXTENSION = /\.zip/
  PDF_EXTENSION = /\.pdf/
  
  def initialize_logfile
    self.image_upload_log << ImageUploadLog.new
    self.image_upload_log.last.save!
  end
  
  def log(msg)
    self.image_upload_log.last.log(msg)
  end
  
  
  def process_file(dir_entry, filename)
    log "process_file called on file #{filename}\n"
    if ImageFile::is_image?filename
      file_entry = ImageFile.create(:image_dir=>dir_entry, :name=>filename, :path=>dir_entry.path) 
    end
    log "process_file done with file #{filename}\n"
  end
  
  def process_pdffile(dir, filename)
    # this works similarly to zipfiles
    log "process_pdffile(#{dir}, #{filename})"
    destination = filename.gsub(PDF_EXTENSION, '')
    log "destination=#{destination}\n"
    ImageFile::extract_pdf(filename, destination)
    process_originals_dir(destination)
  end
  

  
  def process_zipfile(dir, filename)
    # form the new directory name
    log "process_zipfile(#{dir}, #{filename})\n"
    #filename is absolute path, no need to join
    destination = filename.gsub(ZIP_EXTENSION, '')
    log "destination=#{destination}\n"
    unzip_file(filename, destination)
    process_originals_dir(destination)
    
  end
  
  def process_originals_dir(dir)
    # create entry
    log("processing originals directory #{dir}")
    entry = ImageDir.new
    entry.upload = self
    entry.path=dir
    entry.name=File.join(File.basename(self.upload_path), dir.sub(self.originals_dir, ""))
    self.image_dir << entry

    # Create the associated derivation directory
    derived_dir = dir.sub(ORIGINALS_DIR, DERIVATION_DIR)
    Dir.mkdir(derived_dir) unless File.exists?(derived_dir)
    
    # get the beginning state of this dir
    ls = Dir.glob(File.join(entry.path,"*")).sort.map do |fn| 
      rfn = ImageFile.relativize(fn)
      log "\trelativize(#{fn}) yielded #{rfn}"
      rfn
    end
    
    log "contents of #{File.join(entry.path,"*")} are #{ls}"
    
    ls.each do |filename|
      log "considering file #{filename}"      
      # if it's a directory, recur
      if File.directory?(filename)
        log "decided #{filename} is a directory"      
        process_originals_dir(File.join(entry.path,File.basename(filename)))
      else 
        # what kind of file is it?
        if ZIP_EXTENSION.match(filename)
          log "decided #{filename} is a zipfile"      
          process_zipfile(dir, filename)
        else 
          if PDF_EXTENSION.match(filename)
            process_pdffile(dir, filename)
          else
            log "decided #{filename} is a normal file"      
            process_file(entry, filename)
          end
        end
      end
    end
    # finalize entry
    entry.save!
    self.save!
  end
  
  
  def unzip_file (file, destination)
    
    Zip::ZipFile.open(file) do |zip_file|
      zip_file.each do |f|
        f_path=File.join(destination, File.basename(f.name))
        log "\tFile.join(#{destination}, #{File.basename(f.name)})=#{f_path}\n"
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path) unless File.exist?(f_path)
      end
    end
  end
  
  
  def process_upload
    self.status = Status::PROCESSING
    self.save!
    copy_to_originals_dir
    process_originals_dir(self.originals_dir)
    self.status = Status::READY
    self.save!
  end
  
  
  def copy_to_originals_dir
    self.working_dir || initialize_working_dir
    FileUtils.cp_r(Dir.glob(File.join(self.upload_path,"*")), self.originals_dir)
    log "copied contents of #{self.upload_path} to #{self.originals_dir}"
  end
  
  def initialize_working_dir
    self.working_dir = File.join(".", "public", "assets", "images", "working", self.id.to_s)
    Dir.mkdir(self.working_dir)
    self.originals_dir = File.join(self.working_dir, ORIGINALS_DIR)
    Dir.mkdir(self.originals_dir)
    self.derivation_dir = File.join(self.working_dir, DERIVATION_DIR)
    Dir.mkdir(self.derivation_dir)
    self.save!
    
    log "created working directory #{self.working_dir}"
    log "created originals directory #{self.originals_dir}"
    log "created derivation directory #{self.derivation_dir}"
  end
  
  def source_path_is_valid
    path = self[:upload_path]
    if path
      
      unless File.exists?(path) 
        errors.add(:upload_path, "Path #{path} must be a directory on the server.  It appears not to exist.")   
        return
      end
      
      unless File.directory?(path)
        errors.add(:upload_path, "Path #{path} must be a directory on the server.  It appears not to be a directory.")          
        return
      end
      unless File.executable?(path)
        errors.add(:upload_path, "Path #{path} must be an executable directory on the server.  It appears not to be executable by this program, so we cannot change directories to it.")   
        return       
      end
      unless File.readable?(path)
        errors.add(:upload_path, "Path #{path} must be a readable directory on the server.  It appears not to be readable by this program, so we cannot list files in it.")   
        return       
      end
      
      
    end
    
  end
  
  
end
