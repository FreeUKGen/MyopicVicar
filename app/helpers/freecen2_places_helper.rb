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
end
