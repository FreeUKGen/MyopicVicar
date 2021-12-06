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


  def records_for_piece(piece_id,piece_status)
    record_count = 0
    if piece_status == "Online"
      piece = Freecen2Piece.find_by(id: piece_id)
      if piece.present?
        if piece.freecen1_vld_files.present?
          vld_files = piece.freecen1_vld_files
          vld_files.each do |vld_file|
            record_count += vld_file.num_individuals
          end
        else
          if piece.freecen_csv_files.present?
            csv_files = piece.freecen_csv_files
            csv_files.each do |csv_file|
              record_count += csv_file.freecen_csv_entries.count
            end
          end
        end
      end
    end
    return record_count
  end

  def records_for_place(chapman_code, place_description, census)
    record_count = 0
    key_place = Freecen2Content.get_place_key(place_description)
    record_count = @freecen2_contents.records[chapman_code][key_place][census][:records_online]
    return record_count
  end
end
