require 'freecen1_vld_parser'
require 'freecen1_vld_transformer'
require 'freecen1_vld_translator'
namespace :freecen do
  # see http://west-penwith.org.uk/fctools/doc/reference.html
  def process_file(filename)
    print "Processing #{filename}\n"
    parser = Freecen::Freecen1VldParser.new
    file_record = parser.process_vld_file(filename)
    
    transformer = Freecen::Freecen1VldTransformer.new
    transformer.transform_file_record(file_record)   
    
    translator = Freecen::Freecen1VldTranslator.new
    translator.translate_file_record(file_record)
    print "\t#{filename} contained #{file_record.freecen_households.count} households in #{file_record.freecen1_vld_entries.count} entries\n"
  end
  
  desc "Process legacy FreeCEN1 VLD files"
  task :process_freecen1_vld, [:filename] => [:environment] do |t, args| 
    if Dir.exist? args.filename
      Dir.glob(File.join(args.filename, '*.[Vv][Ll][Dd]')).each do |filename|
        process_file(filename)  
      end
    else
      process_file(args.filename)
    end
  end
  
  task :clean_freecen => [:environment] do
    FreecenHousehold.delete_all
    Freecen1VldEntry.delete_all
    Freecen1VldFile.delete_all
  end


end

