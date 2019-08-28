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
    file_record, num_entries = parser.process_vld_file(filename)
    
    transformer = Freecen::Freecen1VldTransformer.new
    transformer.transform_file_record(file_record)
    
    translator = Freecen::Freecen1VldTranslator.new
    num_dwel,num_ind = translator.translate_file_record(file_record)
    #print "\t#{filename} contained #{file_record.freecen_dwellings.count} dwellings in #{file_record.freecen1_vld_entries.count} entries\n"
    print "\t#{filename} contained #{num_dwel} dwellings in #{num_entries} entries\n"
  end
  
  desc "Process legacy FreeCEN1 VLD files"
  task :process_freecen1_vld, [:filename,:report_email] => [:environment] do |t, args|
    vld_err_messages = []
    if Dir.exist? args.filename
      vld_list=Dir.glob(File.join(args.filename, '*.[Vv][Ll][Dd]'))
      ii=1
      vld_list.sort_by{|f| f.downcase}.each do |filename|
        begin
          process_file(filename)
        rescue => e
          p e.message
          vld_err_messages << e.message
        end
        print "\tfinished file number #{ii} of #{vld_list.length}\n"
        ii+=1
      end
    else
      begin
        process_file(args.filename)
      rescue => e
        p e.message
        vld_err_messages << e.message
      end
    end
    report = "No errors reported"
    if vld_err_messages.length > 0
      report = "The following processing error messages were reported:\n"
      vld_err_messages.each do |msg|
        report += "  #{msg}\n"
      end
    end
    p "########################################################"
    puts report
    if !args.report_email.nil?
      require 'user_mailer'
      p "sending email to #{args.report_email} to notify of task completion"
      UserMailer.freecen_processing_report(args.report_email,"FreeCEN VLD processing #{args.filename} ended", report).deliver
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

