task :clean_up_freecen2_pieces, [:limit, :fix] => [:environment] do |t, args|
  p "start clean up  #{args.limit} #{args.fix}"
  process(args.limit, args.fix)
  p 'finished'
end

def process(limit, fix)
  number = 0
  lim = limit.to_i
  fixed = 0
  file_for_warning_messages = "log/clean_up_freecen2_pieces.txt"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  message_file = File.new(file_for_warning_messages, 'w')
  fixit = fix.to_s.downcase == 'y' ? true : false
  p Freecen2Piece.where(year: '1911').count
  Freecen2Piece.where(year: '1911').order_by(name: 1).no_timeout.each do |piece|
    number += 1
    break if number > lim

    p number if (number / 1000) * 1000 == number
    parishes = piece.freecen2_civil_parishes.count
    next if parishes.zero?

    names = []
    piece.freecen2_civil_parishes.each do |parish|
      if parish.standard_name == 'needs_review'
        #delete piece
        piece.freecen2_civil_parishes.delete(parish) if fixit
      elsif names.include?(parish.standard_name)
        piece.freecen2_civil_parishes.delete(parish) if fixit
      else
        names << parish.standard_name
      end
    end
    civil_parish_names = piece.add_update_civil_parish_list
    unless civil_parish_names == piece.civil_parish_names || !fixit
      fixed += 1
      piece.update(civil_parish_names: civil_parish_names)
      message_file.puts "#{piece.chapman_code}, #{piece.name},#{piece.number},#{piece.civil_parish_names}"
    end
  end
  p "Fixed #{fixed}"
  return
end
