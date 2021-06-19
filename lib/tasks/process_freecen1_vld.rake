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
    file.update_attributes(num_individuals: num_ind, num_dwellings: num_dwel)

    piece = file.freecen_piece
    place = Place.find_by(_id: piece.place_id)

    if place.data_present == false
      place.data_present = true
      place_save_needed = true
    end
    if !place.cen_data_years.include?(piece.year)
      place.cen_data_years << piece.year
      place_save_needed = true
    end
    place.save! if place_save_needed
    piece.update_attributes(status: 'Online', status_date: DateTime.now.in_time_zone('London'), num_individuals: num_ind, num_dwellings: num_dwel, num_entries: num_entries) if piece.present?
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
