require 'freecen1_metadata_dat_parser'
require 'freecen1_metadata_dat_transformer'
require 'freecen1_metadata_dat_translator'
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
    print "\t#{filename} contained #{file_record.freecen_dwellings.count} dwellings in #{file_record.freecen1_vld_entries.count} entries\n"
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


  def process_metadata_file(filename)
    print "Processing #{filename}\n"
    parser = Freecen::Freecen1MetadataDatParser.new
    file_record = parser.process_dat_file(filename)
    
    transformer = Freecen::Freecen1MetadataDatTransformer.new
    transformer.transform_file_record(file_record)
    
    translator = Freecen::Freecen1MetadataDatTranslator.new
    translator.translate_file_record(file_record)
    print "\t#{filename} contained #{file_record.freecen1_fixed_dat_entries.count} entries\n"
    
  end

  desc "Process legacy FreeCEN1 DAT files"
  task :process_freecen1_metadata_dat, [:filename] => [:environment] do |t, args| 
    if Dir.exist? args.filename
      Dir.glob(File.join(args.filename, '*.[Dd][Aa][Tt]')).sort.each do |filename|
        process_metadata_file(filename)  
      end
    else
      process_metadata_file(args.filename)
    end
  end
  
  task :clean_freecen => [:environment] do
    SearchRecord.delete_all
    FreecenIndividual.delete_all
    FreecenDwelling.delete_all
    Freecen1VldEntry.delete_all
    Freecen1VldFile.delete_all
  end

  task :clean_freecen_fixed => [:environment] do
    Place.delete_all
    FreecenPiece.delete_all
    Freecen1FixedDatEntry.delete_all
    Freecen1FixedDatFile.delete_all
  end


end

