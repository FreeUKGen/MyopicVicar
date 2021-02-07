class UpdateFreecen2Pieces1861Lnd

  def self.process(limit)
    #The purpose of this clean up utility is to eliminate search records that are unconnected with an entry. Or an entry without a batch
    limit = limit.to_i
    file_for_warning_messages = "log/update_freecen2-pieces_1861_lnd.txt"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages))

    p "Update Freecen2 Piece dropping LND Pieces and Civil Parishes for 1861 with limit of #{limit}"
    records = 0
    fixed = 0
    time_start = Time.new
    p Freecen2Piece.where(year: '1861', chapman_code: 'LND').count
    Freecen2Piece.where(year: '1861', chapman_code: 'LND').no_timeout.each do |piece|

      records += 1
      break if records == limit
      p records

      piece.freecen2_civil_parishes.each do |parish|
        message_file.puts "#{parish.chapman_code}, #{parish.year},#{parish.name}, #{document.name}, has entries and cannot be deleted" if parish.freecen_csv_entries.present?
        next if parish.freecen_csv_entries.present?

        if parish.freecen2_townships.present?
          parish.freecen2_townships.each do |unit|
            unit.deleted
          end
        end
        if parish.freecen2_hamlets.present?
          parish.freecen2_hamlets.each do |unit|
            unit.deleted
          end
        end
        if parish.freecen2_wards.present?
          parish.freecen2_wards.each do |unit|
            unit.deleted
          end
        end
        parish.delete
        fixed += 1
      end
      piece.delete
    end
    time_diff = Time.new - time_start
    average_record = time_diff * 1000 / records
    p 'finished'
    p "#{fixed} fixed in #{records} at average time of #{average_record}"
  end
end
