class ManageParm
	include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  field :year, type: String
  field :chapman_code, type: String
  field :userid, type: String
  field :file_name, type: String
  # => §1	field :actual_file_name, type: String
  validate :validate_file_type#x, on: :save
  validates_presence_of :chapman_code

  DESTINATION = '/raid/freecen2/freecen1/fixed/'
	ALLOWED_FILE_TYPES = ['.dat', '.DAT', '.csv', '.CSV']

  def self.load_parm_files(file, year)
		file_name = file.original_filename
  	file_path = file.tempfile.path

		move_parm_files(file_path, file_name, year)
  end

  def validate_file_type
  	unless ALLOWED_FILE_TYPES.include? File.extname(file_name)
  		errors.add(:file_name, "Invalid File type. Please use CSV or DAT file types")
  	end
  end

  def self.move_parm_files(origin_file_path, file_name, year)
  	destination_file_path = "#{DESTINATION}#{year}"
  	# Create directory if not exists
  	FileUtils.mkdir_p(File.dirname(File.join(destination_file_path, file_name)))

  	# Move parm files to destination
		if File.exists? File.join(destination_file_path, file_name)
			# Add 1- if the filename already exists
  		FileUtils.move origin_file_path, File.join(destination_file_path, "1-#{file_name}")
  	else
  		FileUtils.move origin_file_path, File.join(destination_file_path, file_name)
  	end
  end
end