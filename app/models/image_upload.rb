class ImageUpload
  require 'zip/zip'
  include MongoMapper::Document         
  
  validates_presence_of :path
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
  
  
  key :name, String
  key :path, String
  
  key :working_dir, String

  
  ZIP_EXTENSION = /\.zip/

  def initialize_logfile
    self.image_upload_log << ImageUploadLog.new
    self.image_upload_log.last.save!
  end

  def log(msg)
    self.image_upload_log.last.log(msg)
  end

  
  def process_file(dir_entry, filename)
    log "process_file called on file #{filename}\n"
    file_entry = ImageFile.new
    file_entry.image_dir=dir_entry
    file_entry.name=filename
    file_entry.path=dir_entry.path
  
    file_entry.save!
    log "process_file done with file #{filename}\n"
  end
  
  def process_zipfile(working_dir, filename)
    # form the new directory name
    log "process_zipfile(#{working_dir}, #{filename})\n"
    #filename is absolute path, no need to join
    destination = filename.gsub(ZIP_EXTENSION, '')
    log "destination=#{destination}\n"
    unzip_file(filename, destination)
    process_working_dir(destination)
    
  end
  
  def process_working_dir(dir)
    # create entry
    log("processing working directory #{dir}")
    entry = ImageDir.new
    entry.image_upload = self
    entry.path=dir
    entry.name=dir
    self.image_dir << entry

    # get the beginning state of this dir
    ls = Dir.glob(File.join(entry.path,"*")).sort

    log "contents of #{File.join(entry.path,"*")} are #{ls}"
    
    ls.each do |filename|
      log "considering file #{filename}"      
      # if it's a directory, recur
      if File.directory?(filename)
        log "decided #{filename} is a directory"      
        process_working_dir(File.join(entry.path,filename))
      else 
        # what kind of file is it?
        if ZIP_EXTENSION.match(filename)
          log "decided #{filename} is a zipfile"      
          process_zipfile(dir, filename)
        else
          log "decided #{filename} is a normal file"      
          process_file(entry, filename)
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
  
  def copy_to_working_dir
    self.working_dir || initialize_working_dir
    FileUtils.cp_r(Dir.glob(File.join(self.path,"*")), self.working_dir)
    log "copied contents of #{self.path} to #{self.working_dir}"
  end
  
  def initialize_working_dir
    self.working_dir = File.join(Dir.getwd, "public", "images", "working", self.id.to_s)
    Dir.mkdir(self.working_dir)
    self.save!
    
    log "created working directory #{self.working_dir}"
  end
  
  def source_path_is_valid
    path = self[:path]
    if path
      
      unless File.exists?(path) 
        #errors.add(:path, "Path #{path} must be a directory on the server.  It appears not to exist.")       
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
