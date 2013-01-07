require 'freereg_csv_processor'

desc "Process a csv file or dictory specified thus: process_freereg_csv[../*/*.csv]"
task :process_freereg_csv, [:pattern] => [:environment] do |t, args| 
  # if we ever need to switch this to multiple files, see
  # http://stackoverflow.com/questions/3586997/how-to-pass-multiple-parameters-to-rake-task
  #print "Processing file passed in rake process_freereg_csv[filename]=#{args[:file]}\n" 
  FreeregCsvProcessor.prove_you_exist
  filenames = Dir.glob(args[:pattern])
  filenames.each do |fn|
  	FreeregCsvProcessor.process(fn)
  end
  puts "Task complete."
end
