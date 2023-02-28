module Freecen2PlacesHelper


  def alternate(place)
    field = ''
    place.alternate_freecen2_place_names.each_with_index do |place_name, ind|
      field += ', ' if ind > 0
      field += place_name.alternate_name
    end
    field
  end

  def official_source(url)
    if url =~ /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix
      #    link_to 'Location', "https://www.google.com/maps/@?api=1&map_action=map&center=#{latitude},#{longitude}&zoom=13", target: :_blank, title: 'Shows the location on a Google map'
      link_to 'Link to Official Source', "#{url}", target: :_blank, class: 'btn   btn--small', title: 'Links to an official source of the information'
    else
      'No official link'
    end
  end

  def link_edits(place)
    if place.freecen2_place_edits.count > 0
      link_to "#{place.freecen2_place_edits.count}", show_place_edits_freecen2_place_path(place.id), class: 'btn   btn--small', title: 'Links to a listing of edits'
    else
      'none'
    end
  end

  def format_alternates(edit)
    alternates = edit.previous_alternate_place_names
    result = ''
    if alternates.present?
      alternates.each do |name|
        result = result + name + ', '
      end
      result = result.gsub(/,\s$/, '')
    end
  end

  def piece_element(place)
    if place.freecen2_pieces.count > 0
      online_pieces = 0
      place.freecen2_pieces.each do |piece|
        online_pieces += 1 if piece.status == 'Online'
      end
      link_to "#{place.freecen2_pieces.count} (#{online_pieces})", place_pieces_index_freecen2_piece_path(place: place.id), class: 'btn   btn--small', title: 'Links to a listing of the pieces'
    else
      'none'
    end
  end

  def cen_years(cen_data_years)
    data_years = cen_data_years.present? ? cen_data_years.sort : ''
  end

  def search_names_clear_form
    link_to 'Clear Form', search_names_freecen2_place_path(clear_form: true), class: 'btn btn--small'
  end
end
