desc "Check freereg1_csv_file locations records are correct, setting fix to fix will correct it"
require 'chapman_code'

task :check_cen_data_years_for_csv, [:limit] => :environment do |t, args|
  file_count = 0
  p 'starting csv'
  FreecenCsvFile.where(incorporated: true).order_by(_id: -1).no_timeout.each do |file|
    file_count += 1
    break if file_count == args.limit.to_i

    p file_count
    p "#{file._id} #{file.chapman_code} #{file.file_name}"
    piece = file.freecen2_piece
    p "Piece #{piece.number}"
    piece.freecen2_civil_parishes.no_timeout.each do |civil_parish|
      p "Bypassing #{civil_parish.name}" if civil_parish.freecen_csv_entries.blank?
      next if civil_parish.freecen_csv_entries.blank?

      freecen2_place = civil_parish.freecen2_place
      if freecen2_place.present? && !freecen2_place.cen_data_years.include?(piece.year)
        cen_data = cen_data_years
        cen_data << piece.year
      end
      p "Updating #{civil_parish.name} #{freecen2_place.cen_data_years} with #{cen_data}"
      freecen2_place.update_attributes(data_present: true, cen_data_years: cen_data) if cen_data.present?

      p "#{freecen2_place.place_name} updated"

    end
  end
  p 'finished csv'
end
