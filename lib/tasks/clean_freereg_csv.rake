require 'freereg_csv_processor'

desc "Process a filename specified thus: process_freereg_csv[filename]"
task :clean_freereg_csv => :environment do 
  # if we ever need to switch this to multiple files, see
  # http://stackoverflow.com/questions/3586997/how-to-pass-multiple-parameters-to-rake-task
#  FreeregCsvProcessor.prove_you_exist
  FreeregCsvProcessor.delete_all
end
