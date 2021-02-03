class Freecen2PiecesRefreshCivilParishList

  def self.process(limit, fix)
    #The purpose of this clean up utility is to eliminate search records that are unconnected with an entry. Or an entry without a batch
    limit = limit.to_i
    file_for_warning_messages = "log/refresh_freecen2-pieces_civil_parish.txt"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
    message_file = File.new(file_for_warning_messages, 'w')
    fixit = fix.to_s.downcase == 'y' ? true : false
    p "Refresh Civil Piece Civil Parish list with limit of #{limit} and fix is #{fix}"
    records = 0
    fixed = 0
    time_start = Time.now
    Freecen2Piece.no_timeout.each do |document|
      records += 1
      break if fixed == limit

      civil_parish_names = document.add_update_civil_parish_list
      next if civil_parish_names == document.civil_parish_names

      fixed += 1
      document.update(civil_parish_names: civil_parish_names)
      message_file.puts "#{document.chapman_code}, #{document.year},#{document.name},#{document.number},#{document.civil_parish_names}"
    end
    time_diff = Time.now - time_start
    average_record = time_diff * 1000 / records
    p 'finished'
    p "#{fixed} fixed in #{records} at average time of #{average_record}"
  end
end
