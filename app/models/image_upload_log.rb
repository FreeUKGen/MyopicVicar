class ImageUploadLog
  include MongoMapper::Document         

  require 'date'

# Validations :::::::::::::::::::::::::::::::::::::::::::::::::::::
# validates_presence_of :attribute

# Assocations :::::::::::::::::::::::::::::::::::::::::::::::::::::
# belongs_to :model
# many :model
# one :model
  belongs_to :image_upload


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
  
   
  key :file, String
  timestamps!

  def initialize_logfile
    dirname = File.join("log/upload", Date.today.to_s)
    FileUtils.mkdir(dirname) unless File.directory?(dirname)
    self.file = File.join(dirname, "upload_#{self.id}.log")
    @logger = Logger.new(self.file)
    @logger.level = Logger::INFO
    @logger.info "Created logfile #{self.file}."
    self.save!
  end

  def log(msg)
    @logger || initialize_logfile
    @logger.info(msg)
  end

  def read
    File.read(self.file)
  end

end
