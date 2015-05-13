require 'freecen1_vld_parser'
require 'freecen1_vld_transformer'
namespace :freecen do
  # see http://west-penwith.org.uk/fctools/doc/reference.html
  desc "Process legacy FreeCEN1 VLD files"
  task :process_freecen1_vld, [:filename] => [:environment] do |t, args| 
    parser = Freecen::Freecen1VldParser.new
    file_record = parser.process_vld_file(args.filename)
    
    transformer = Freecen::Freecen1VldTransformer.new
    transformer.transform_file_record(file_record)
  end
  
  task :clean_freecen => [:environment] do
    FreecenHousehold.delete_all
    Freecen1VldEntry.delete_all
    Freecen1VldFile.delete_all
  end


end

