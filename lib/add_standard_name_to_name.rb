class AddStandarNameToName
  def self.process(limit)
    #The purpose of this clean up utility is to eliminate search records that are unconnected with an entry. Or an entry without a batch

    p "#{limit}"
    time_start = Time.now
    record = 0
    limit = limit.to_i
    Freecen2District.no_timeout.each do |district|
      district.freecen2_pieces.each do |piece|
        piece.freecen2_civil_parishes.each do |parish|
          parish.save
          record += 1
          break if record == limit
        end
        piece.save
        break if record == limit
      end
      district.save
      break if record == limit
    end
    time = Time.now - time_start
    p "finished #{time}"
  end
end
