class EditFreecen2Name

  def self.process(type, chapman_code, limit, fix)
    #The purpose of this clean up utility is to eliminate search records that are unconnected with an entry. Or an entry without a batch
    bad_text = /[-_,'"]/
    bad_text_less = /[-_,"]/
    bad_s = /'/
    limit = limit.to_i
    chapman_code = chapman_code.upcase
    file_for_warning_messages = "log/edit_freecen2_name_#{chapman_code}_#{type}.txt"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
    message_file = File.new(file_for_warning_messages, 'w')
    fixit = fix.to_s.downcase == 'y' ? true : false
    p "Editing names for #{type} in #{chapman_code} with limit of #{limit} and fix is #{fix}"
    message_file.puts  'Chapman code, year, old name, new name'
    records = 0
    fixed = 0
    time_start = Time.now
    case type.titleize
    when 'District'
      if chapman_code == 'ALL'
        documents = Freecen2District.all
      else
        documents = Freecen2District.where(chapman_code: chapman_code).all
      end
    when 'Piece'
      if chapman_code == 'ALL'
        documents = Freecen2Piece.all
      else
        documents = Freecen2Piece.where(chapman_code: chapman_code).all
      end
    when 'Civil Parish'
      if chapman_code == 'ALL'
        documents = Freecen2CivilParish.all
      else
        documents = Freecen2CivilParish.where(chapman_code: chapman_code).all
      end
    end

    documents.each do |document|
      records += 1
      fix_name = document.name =~ bad_text ? true : false
      next unless fix_name

      fixed += 1
      break if fixed == limit

      new_name = document.name.gsub(bad_text_less, ' ').gsub(bad_s, '').gsub(/ +/, ' ')
      message_file.puts "#{chapman_code},#{document.year},\"#{document.name}\",\"#{new_name}\""
      document.update_attributes(name: new_name) if fixit
    end
    time_diff = Time.now - time_start
    average_record = time_diff * 1000 / records
    p 'finished'
    p "#{fixed} fixed in #{records} at average time of #{average_record}"
  end
end
