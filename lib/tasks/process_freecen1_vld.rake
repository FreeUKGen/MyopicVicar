require 'freecen1_vld_parser'
require 'freecen1_vld_transformer'
require 'freecen1_vld_translator'
namespace :freecen do
  # see http://west-penwith.org.uk/fctools/doc/reference.html
  def process_vld_file(filename)
    print "Processing VLD #{filename}\n"
    parser = Freecen::Freecen1VldParser.new
    file, num_entries = parser.process_vld_file(filename)

    transformer = Freecen::Freecen1VldTransformer.new
    transformer.transform_file_record(file)

    translator = Freecen::Freecen1VldTranslator.new
    num_dwel, num_ind = translator.translate_file_record(file)

    piece = file.freecen_piece
    piece.update_attribute(:status, 'Online') if piece.present?
    #print "\t#{filename} contained #{file_record.freecen_dwellings.count} dwellings in #{file_record.freecen1_vld_entries.count} entries\n"
    print "\t#{filename} contained #{num_dwel} dwellings #{num_ind} individuals in #{num_entries} entries\n"
  end

  desc "Process legacy FreeCEN1 VLD file"
  task :process_freecen1_vld, [:filename, :report_email] => [:environment] do |t, args|
    vld_err_messages = []
    begin
      process_vld_file(args.filename)
    rescue => e
      p e.message
      vld_err_messages << e.message
    end

    report = "No errors reported"
    if vld_err_messages.length > 0
      report = "The following processing error messages were reported:\n"
      vld_err_messages.each do |msg|
        report += "  #{msg}\n"
      end
    end
    puts report
    if args.report_email.present?
      require 'user_mailer'
      userid = UseridDetail.userid(args.report_email).first
      if userid.present?
        friendly_email = "#{userid.person_forename} #{userid.person_surname} <#{userid.email_address}>"
      else
        friendly_email = "#{appname} Servant <#{appname}-processing@#{appname}.org.uk>"
      end
      p "sending email to #{args.report_email} to notify of task completion"
      UserMailer.freecen_processing_report(friendly_email, "FreeCEN VLD processing #{args.filename} ended", report).deliver
    end
  end
end
