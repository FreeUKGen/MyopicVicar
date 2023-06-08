desc 'Update Gazetteer OVB to OVF'
task :update_gaz_ovb_to_ovf, [:fix] => :environment do |t, args|

  file_for_listing = 'log/update_gaz_ovb_to_ovf.csv'
  FileUtils.mkdir_p(File.dirname(file_for_listing)) unless File.exist?(file_for_listing)
  file_for_listing = File.new(file_for_listing, 'w')
  fixit = args.fix.to_s == 'Y'
  p "Started Update of Gazetteer OVB to OVF  with fix #{fixit}"
  fixit =  args.fix.to_s.downcase == 'y' ? true : false
  recs_processed = 0
  file_for_listing.puts 'Chapman_code,County,Place_name,Standard_place_name,Location,URL,Place_notes,Standard_alternate_names,Id,Action'

  ovb_places = Freecen2Place.where(:chapman_code => 'OVB').order_by(:standard_place_name => 1)
  ovb_places.each do |ovb_rec|

    ovf_place = Freecen2Place.find_by(chapman_code: 'OVF', standard_place_name: ovb_rec.standard_place_name)
    if ovf_place.present?
      action = 'Delete OVB record as OVF already present for this place'
    else
      action = 'Update chapman_code to OVF as no OVF record exists for this place'
    end
    alt_names = ''
    if ovb_rec.alternate_freecen2_place_names.present?
      ovb_rec.alternate_freecen2_place_names.each do |alternate|
        alt_names += ", #{alternate.standard_alternate_name}"
      end
    end
    alt_names = alt_names[2..-1] if alt_names.length.positive?

    line = ''
    line << "#{ovb_rec.chapman_code},"
    line << "#{ovb_rec.county},"
    line << "\"#{ovb_rec.place_name}\","
    line << "\"#{ovb_rec.standard_place_name}\","
    line << "\"#{ovb_rec.location}\","
    line << "\"#{ovb_rec.genuki_url}\","
    line << "\"#{ovb_rec.place_notes}\","
    line << "\"#{alt_names}\","
    line << "\"#{ovb_rec._id}\","
    line << "#{action}"
    file_for_listing.puts line

    if fixit
      if ovf_place.present?
        ovb_rec.delete
      else
        ovb_rec.update_attributes(chapman_code: 'OVF', county: 'Overseas Foreign')
      end
    end
    recs_processed += 1

  end

  p 'Finished Update of Gazetteer OVB to OVF'
  p "Processed #{recs_processed} OVB Gazetteer records - see log/update_gaz_ovb_to_ovf.csv for output"
end
