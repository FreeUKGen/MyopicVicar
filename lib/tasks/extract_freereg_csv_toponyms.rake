
require "csv"

desc "Extracts toponyms from a set of files"
task :extract_freereg_csv_toponyms, [:pattern] => [:environment] do |t, args| 
  # if we ever need to switch this to multiple files, see
  # http://stackoverflow.com/questions/3586997/how-to-pass-multiple-parameters-to-rake-task
#  FreeregCsvProcessor.prove_you_exist
  filenames = Dir.glob(args[:pattern])
  filenames.each do |fn|
#    p "Extracting toponyms from #{fn}\n"
    # get the filename
    standalone_filename = File.basename(fn)
    # get the user ID represented by the containing directory
    full_dirname = File.dirname(fn)
    parent_dirname = File.dirname(full_dirname)
    user_dirname = full_dirname.sub(parent_dirname, '').gsub(File::SEPARATOR, '')
    
    # TODO convert character sets as in freereg_csv_processor
    charset = "iso-8859-1"
    file = File.new(fn, "r" , external_encoding:charset , internal_encoding:"UTF-8")
  
    # skip the first five-ish lines
    4.times { line = file.gets }
    if file
      line = file.gets
    end
    CSV.parse(line) do |data|
      print "#{standalone_filename},#{user_dirname},#{data[0]},#{data[1]},#{data[2]}\n"
    end


    
#    p "#{user_dirname}  #{standalone_filename}\n"
  end
end
