require 'freecen1_vld_parser'
require 'freecen1_vld_transformer'
require 'freecen1_vld_translator'
namespace :freecen do
  # see http://west-penwith.org.uk/fctools/doc/reference.html

  def process_vld_file(filename, userid)
    print "Processing VLD #{filename}\n"
    parser = Freecen::Freecen1VldParser.new
    file, num_entries = parser.process_vld_file(filename, userid)

    piece = file.freecen_piece
    freecen2_piece, freecen2_place = Freecen2Piece.find_by_vld_file_name(piece)
    raise "Unable to locate a Freecen2 Piece for this number #{piece_number} " if freecen2_piece.blank?

    raise "This Freecen2 Piece number #{piece_number} does not have a Freecen2 Place" if freecen2_place.blank?

    piece.update_attributes(freecen2_place_id: freecen2_place.id)
    transformer = Freecen::Freecen1VldTransformer.new
    transformer.transform_file_record(file)
    translator = Freecen::Freecen1VldTranslator.new
    num_dwel, num_ind = translator.translate_file_record(file)
    file.update_attributes(num_individuals: num_ind, num_dwellings: num_dwel)
    file.search_records.each do |record|
      freecen2_place.search_records << record
    end
    file.freecen_dwellings.each do |record|
      freecen2_place.freecen_dwellings << record
    end
    p "\t#{filename} contained #{num_dwel} dwellings #{num_ind} individuals in #{num_entries} entries\n"
    freecen2_piece.update_attributes(status: 'Online', status_date: DateTime.now.in_time_zone('London'), num_individuals: num_ind, num_dwellings: num_dwel) if freecen2_piece.present?
    freecen2_piece.update_parts_status_on_file_upload(file, piece)
    freecen2_piece.freecen1_vld_files << [file]
    freecen2_piece.save!
    freecen2_place.freecen1_vld_files << [file]
    freecen2_place.data_present = true
    freecen2_place.cen_data_years << freecen2_piece.year unless freecen2_place.cen_data_years.include?(freecen2_piece.year)
    freecen2_place.save!
    freecen2_district = freecen2_piece.freecen2_district
    freecen2_district.freecen1_vld_files << [file]
    freecen2_district.save!
    Freecen2PlaceCache.refresh(freecen2_place.chapman_code)
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
