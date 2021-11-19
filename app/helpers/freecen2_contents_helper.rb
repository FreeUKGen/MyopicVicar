module Freecen2ContentsHelper

  def contents_show_percentage(pieces_online, pieces)
    percent = 0
    percent = ((pieces_online.to_f / pieces.to_f) * 100).round(1) if pieces_online > 0
    display_cell = content_tag(:td, percent.to_s)
  end

  def choose_another_place_link(county_description)
    return link_to 'Choose another Place',index_by_county_freecen2_contents_path(county_description: county_description),method: :get,:class => 'btn btn--small'
  end

  def names_exist_for_place_year(place_id, year)
    has_names = false
    names =  Freecen2PlaceUniqueName.find_by(freecen2_place_id: place_id)
    if names.present? and names.unique_forenames[year].present? and names.unique_surnames[year].present?
      has_names = true
    end
    return has_names
  end

  def locate_place_link(place_id)
    place = Freecen2Place.find_by(id: place_id)
    link_to 'Location', "https://www.google.com/maps/search/?api=1&query=#{place.latitude},#{place.longitude}", target: :_blank, class: 'btn   btn--small', title: 'Shows the location on a Google map in a new tab'
  end

end
