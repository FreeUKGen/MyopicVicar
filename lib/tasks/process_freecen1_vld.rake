require 'freecen1_vld_parser'
require 'freecen1_vld_transformer'
require 'freecen1_vld_translator'
namespace :freecen do
  # see http://west-penwith.org.uk/fctools/doc/reference.html

  def update_cache(place, piece)
    raise "No place" if place.blank?

    if place.data_present == false
      place.data_present = true
      place_save_needed = true
    end
    if !place.cen_data_years.include?(piece.year)
      place.cen_data_years << piece.year
      place_save_needed = true
    end
    place.save! if place_save_needed
  end

  def process_vld_file(filename, userid)
    print "Processing VLD #{filename}\n"
    parser = Freecen::Freecen1VldParser.new
    file, num_entries = parser.process_vld_file(filename, userid)
    piece = file.freecen_piece
    # This code creates a freecen2Place link for the piece if one does not exist
    freecen2_place = piece.freecen2_place
    if freecen2_place.blank?
      year, piece_number = Freecen2Piece.extract_freecen2_piece_vld(file.file_name)
      freecen2_piece = Freecen2Piece.find_by(year: year, number: piece_number)
      raise "Unable to locate a Freecen2 Piece for this number #{piece_number} " if freecen2_piece.blank?

      freecen2_place = freecen2_piece.freecen2_place
      raise "This Freecen2 Piece number #{piece_number} does not have a Freecen2 Place" if freecen2_place.blank?

      piece.update_attributes(freecen2_place_id: freecen2_place.id)
    end
    transformer = Freecen::Freecen1VldTransformer.new
    transformer.transform_file_record(file)
    translator = Freecen::Freecen1VldTranslator.new
    num_dwel, num_ind = translator.translate_file_record(file)
    file.update_attributes(num_individuals: num_ind, num_dwellings: num_dwel)

    # This code update the freecen2_place data present and the cen data years -------------------------------
    place = Freecen2Place.find_by(_id: piece.freecen2_place_id)
    update_cache(place, piece)
    # ----------------------------------------------------------------------------------------------


    # This code update the place data present and the cen data years -------------------------------
    place = Place.find_by(_id: piece.place_id)
    update_cache(place, piece)
    # ----------------------------------------------------------------------------------------------
    piece.update_attributes(status: 'Online', status_date: DateTime.now.in_time_zone('London'), num_individuals: num_ind, num_dwellings: num_dwel, num_entries: num_entries) if piece.present?
    #print "\t#{filename} contained #{file_record.freecen_dwellings.count} dwellings in #{file_record.freecen1_vld_entries.count} entries\n"
    print "\t#{filename} contained #{num_dwel} dwellings #{num_ind} individuals in #{num_entries} entries\n"
  end

  desc "Process legacy FreeCEN1 VLD file"
  task :process_freecen1_vld, [:filename, :report_email] => [:environment] do |t, args|
    vld_err_messages = []
    begin
      process_vld_file(args.filename, args.report_email)
    rescue => e
      p e.message
      vld_err_messages << e.message
      vld_err_messages << "#{e.backtrace.inspect}"
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
