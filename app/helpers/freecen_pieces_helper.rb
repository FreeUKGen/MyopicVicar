module FreecenPiecesHelper
  #return hyperlink to map lat,long (unless 0,0 or 60,0; then just return text)
  def map_link_helper(text, lat, long, zoom=10, title='Show on Map')
    return text if (0.0==lat.to_f || 60.0==lat.to_f) && 0.0==long.to_f
    if(true)#google maps
      return raw '<a href="https://google.com/maps/place/'+(lat.to_f.to_s)+','+(long.to_f.to_s)+'/@'+(lat.to_f.to_s)+','+(long.to_f.to_s)+','+(zoom.to_i.to_s)+'z" target="_blank" title="'+(title.to_s)+'">'+(text.to_s)+'</a>'
    else#openstreetmap.org
      return raw '<a href="https://www.openstreetmap.org/?mlat='+(lat.to_f.to_s)+'&mlon='+(long.to_f.to_s)+'#map='+(zoom.to_i.to_s)+'/'+(lat.to_f.to_s)+'/'+(long.to_f.to_s)+'" target="_blank" title="'+(title.to_s)+'">'+(text.to_s)+'</a>'
    end
  end

  def sub_pieces(subplaces)
    place_names = []
    subplaces.each do |place|
      place_names << place[:name] if place[:name].present?
    end
    place_names.sort_by! { |e| ActiveSupport::Inflector.transliterate(e.downcase) }
    place_names.join(', ')
  end

  def piece_number(file)
    actual_piece = file.freecen_piece
    piece_number = actual_piece.piece_number
  end

  def chapman(file)
    actual_piece = file.freecen_piece
    piece_number = actual_piece.chapman_code
  end

  def year(file)
    actual_piece = file.freecen_piece
    piece_number = actual_piece.year
  end

  def district_name(file)
    actual_piece = file.freecen_piece
    piece_number = actual_piece.district_name
  end

  def vldfile(file_name)
    file = Freecen1VldFile.find_by(file_name: file_name)
    link_to "#{file_name}" , freecen1_vld_file_path(file.id), class: 'btn   btn--small' if file.present?
  end

  def status_date(piece)
    if piece.status_date.present?
      piece.status_date
    else
      piece.id.generation_time.strftime('%Y-%m-%d %H:%M') if piece.id.present?
    end
  end
end
