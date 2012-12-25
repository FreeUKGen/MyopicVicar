require 'freereg_csv_processor'

desc "Process a filename specified thus: process_freereg_csv[filename]"
task :process_freereg_csv, [:file] => [:environment] do |t, args|
  # if we ever need to switch this to multiple files, see
  # http://stackoverflow.com/questions/3586997/how-to-pass-multiple-parameters-to-rake-task
  print "Processing file passed in rake process_freereg_csv[filename]=#{args[:file]}\n" 
#  FreeregCsvProcessor.prove_you_exist
  FreeregCsvProcessor.process(args[:file])
  puts "Task complete."
end
