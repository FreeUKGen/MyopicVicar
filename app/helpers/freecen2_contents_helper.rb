module Freecen2ContentsHelper

  def contents_show_percentage(pieces_online, pieces)
    percent = 0
    percent = ((pieces_online.to_f / pieces.to_f) * 100).round(1) if pieces_online > 0
    display_cell = content_tag(:td, percent.to_s)
  end

  def choose_another_county_link
    return link_to 'Choose another County',freecen2_contents_path,method: :get,:class => 'btn btn--small'
  end

  def choose_another_district_link(county_description)
    return link_to 'Choose another District',index_by_county_freecen2_contents_path(county_description: county_description),method: :get,:class => 'btn btn--small'
  end

  def choose_another_place_link(county_description, district_description, key_district)
    return link_to 'Choose another Place',index_by_district_freecen2_contents_path(county_description: county_description, district_description: district_description, key_district: key_district),method: :get,:class => 'btn btn--small'
  end

end
