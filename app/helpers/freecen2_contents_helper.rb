module Freecen2ContentsHelper
  def contents_check_for_partials(piece_ids, pieces_online)
    partial_flag = ''
    # if piece_ids.blank? || pieces_online.blank?
    if piece_ids.blank?
      display_val = '0'
    else
      piece_ids.each do |piece_id|
        partial_flag = '*' if Freecen2Piece.find_by(id: piece_id, status: 'Part').present?
        break if partial_flag == '*'
      end
      display_val = pieces_online.to_s + partial_flag
    end
    content_tag(:td, display_val)
  end

  def contents_show_percentage(pieces_online, pieces)
    percent = 0
    percent = ((pieces_online.to_f / pieces.to_f) * 100).round(1) if pieces_online.positive?
    content_tag(:td, percent.to_s)
  end

  def county_index_link(county_description, place_description)
    if place_description == 'all'
      return link_to "Back to Records for #{county_description}", index_by_county_freecen2_contents_path(county_description: county_description), method: :get, :class => 'btn btn--small'
    else
      return link_to "Choose another Place in #{county_description}", index_by_county_freecen2_contents_path(county_description: county_description), method: :get, :class => 'btn btn--small'
    end
  end

  def names_exist_for_place_year(place_id, year)
    has_names = false
    names = Freecen2PlaceUniqueName.find_by(freecen2_place_id: place_id)
    if names.present? && names.unique_forenames[year].present? && names.unique_surnames[year].present?
      has_names = true
    end
    return has_names
  end

  def locate_place_link(place_id, button_size)
    place = Freecen2Place.find_by(id: place_id)
    if button_size == 'exsmall'
      link_to 'Location', "https://www.google.com/maps/search/?api=1&query=#{place.latitude},#{place.longitude}", target: :_blank, class: 'btn   btn--exsmall', title: 'Shows the location on a Google map in a new tab'
    else
      link_to 'Location', "https://www.google.com/maps/search/?api=1&query=#{place.latitude},#{place.longitude}", target: :_blank, class: 'btn   btn--small', title: 'Shows the location on a Google map in a new tab'
    end
  end

  def records_for_piece(piece_id, piece_status)
    record_count = 0
    if %w[Online Part].include?(piece_status)
      piece = Freecen2Piece.find_by(id: piece_id)
      if piece.present?
        if piece.freecen1_vld_files.present?
          vld_files = piece.freecen1_vld_files
          vld_files.each do |vld_file|
            record_count += vld_file.num_individuals
          end
        elsif piece.freecen_csv_files.present?
          csv_files = piece.freecen_csv_files
          csv_files.each do |csv_file|
            if csv_file.incorporated == true
              record_count += csv_file.freecen_csv_entries.count
            end
          end
        end
      end
    end
    return record_count
  end
end
