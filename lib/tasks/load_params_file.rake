DESTINATION = '/Users/krish/Downloads/'
ALLOWED_FILE_TYPES = ['*.dat', '*.csv', '*.DAT', '*.CSV']


def load_params(origin, file_type)
  Dir.glob(File.join(origin, file_type)).each do |file|
  	if File.exists? File.join(DESTINATION, File.basename(file))
  		FileUtils.move file, File.join(DESTINATION, "1-#{File.basename(file)}")
  	else
  		FileUtils.move file, File.join(DESTINATION, File.basename(file))
  	end
  end
end

ALLOWED_FILE_TYPES.each do |file_type|
	desc "Moving all the #{file_type} files"
	task :load_params_file, [:origin] => :environment do |t, args|
  	load_params(args.origin, file_type)
	end
end