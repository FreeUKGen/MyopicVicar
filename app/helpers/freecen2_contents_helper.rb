module Freecen2ContentsHelper

  def contents_show_percentage(pieces_online, pieces)
    percent = 0
    percent = ((pieces_online.to_f / pieces.to_f) * 100).round(1) if pieces_online > 0
    display_cell = content_tag(:td, percent.to_s)
  end

  def choose_another_place_link(county_description)
    return link_to 'Choose another Place',index_by_county_freecen2_contents_path(county_description: county_description),method: :get,:class => 'btn btn--small'
  end

  def get_place_id(county_name, place_name)
    chapman_code = ChapmanCode.code_from_name(county_name)
    place = Freecen2Place.find_by(chapman_code: chapman_code, place_name: place_name)
    return place.id
  end

  def names_exist_for_place_year(county_name, place_name, year)
    has_names = false
    chapman_code = ChapmanCode.code_from_name(county_name)
    place = Freecen2Place.find_by(chapman_code: chapman_code, place_name: place_name)
    names =  Freecen2PlaceUniqueName.find_by(freecen2_place_id: place.id)
    if names.present? and names.unique_forenames[year].present? and names.unique_surnames[year].present?
      has_names = true
    end
    return has_names
  end

end
