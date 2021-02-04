class UpdateFreecen2Pieces1911

  def self.process(limit)
    #The purpose of this clean up utility is to eliminate search records that are unconnected with an entry. Or an entry without a batch
    limit = limit.to_i
    file_for_warning_messages = 'log/update_freecen2-pieces_1911.txt'
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages))

    p "Update Freecen2 Piece dropping Civil Parishes for 1911 with limit of #{limit}"
    records = 0
    fixed = 0
    time_start = Time.new
    p Freecen2Piece.year('1911').count
    Freecen2Piece.year('1911').no_timeout.each do |piece|
      records += 1
      p records if (records / 1000) * 1000 == records
      break if fixed == limit

      next if piece.freecen2_civil_parishes.length.zero? || piece.freecen2_civil_parishes.length == 1

      fixed += 1
      piece.freecen2_civil_parishes.each do |parish|
        message_file.puts "#{parish.chapman_code}, #{parish.year},#{parish.name}, #{piece.name}, has entries and cannot be deleted" if parish.freecen_csv_entries.present?
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
      end
      new_parish = Freecen2CivilParish.new(name: 'Needs_review', year: '1911', chapman_code: piece.chapman_code, freecen2_piece_id: piece.id)
      new_parish.save
      piece.reload
      civil_parish_names = piece.add_update_civil_parish_list
      piece.update(civil_parish_names: civil_parish_names)
    end

    time_diff = Time.new - time_start
    average_record = time_diff * 1000 / records
    p 'finished'
    p "#{fixed} fixed in #{records} at average time of #{average_record}"
  end
end
