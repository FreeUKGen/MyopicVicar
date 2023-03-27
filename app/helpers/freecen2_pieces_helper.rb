module Freecen2PiecesHelper

  def tna(number)
    if number.to_s == 'None'
      "#{number}"
    else
      link_to 'The National Archive', "https://discovery.nationalarchives.gov.uk/browse/r/h/#{number}", target: :_blank, class: 'btn   btn--small', title:'Access to The National Archive'
    end
  end

  def district_link(district)
    if district.present?
      link_to "#{district.name}", freecen2_district_path(district), class: 'btn   btn--small', title:' Displays all of the information about the District to which this Sub District (Piece) is linked'
    else
      'There is no district'
    end
  end

  def civil_link(piece)
    if piece.present?
      link_to 'Civil Parishes', index_for_piece_freecen2_civil_parishes_path(piece_id: piece.id, type: @type), class: 'btn   btn--small', title:' Displays a list of the Civil Parishes which belong to this Sub District (Piece)'
    else
      'There is no piece'
    end
  end

  def csv_files_piece_unincorporated(piece)
    if piece.freecen_csv_files.present?
      files = []
      piece.freecen_csv_files.incorporated(false).order_by(file_name: 1).each do |file|
        if file.userid.blank?
          files << file.file_name + ' ()'
        else
          files << file.file_name + ' (' + file.userid + ')'
        end
      end
      files
    else
      'There are no unincorporated CSV files'
    end
  end

  def csv_files_piece_incorporated(piece)
    if piece.freecen_csv_files.present?
      files = []
      piece.freecen_csv_files.incorporated(true).order_by(file_name: 1).each do |file|
        if file.userid.blank?
          files << file.file_name + ' ()'
        else
          files << file.file_name + ' (' + file.userid + ')'
        end
      end
      files
    else
      'There are no incorporated CSV files'
    end
  end

  def vld_files_piece(piece)
    if piece.freecen1_vld_files.present?
      # normal link to vld file (usually only 1)
      files = []
      piece.freecen1_vld_files.order_by(file_name: 1).each do |file|
        if file.userid.blank?
          files << file.file_name
        else
          files << file.file_name + ' (' + file.userid + ')'
        end
      end
      files
    elsif piece.vld_files.present?
      # used for Scotland pieces where there can be multiple files for a single piece
      piece.vld_files
    elsif piece.shared_vld_file.present?
      # used when a file has multiple pieces; usually only occurs with piece has been broken into parts
      file = Freecen1VldFile.find_by(_id: piece.shared_vld_file)
      file.file_name if file.present?
    else
      'There are no VLD files'
    end
  end


  def piece_status(piece)
    if piece.status.present?
      status = piece.status_date.present? ? piece.status + " (" + piece.status_date.to_datetime.strftime("%d/%b/%Y %R") + ")" : piece.status
    end
  end

  def csv_files_piece_link_unincorporated(piece)
    if piece.present?
      link_to 'Unincorporated Freecen CSV Files', freecen_csv_files_path, class: 'btn   btn--small', title: 'Csv files for this Piece'
    else
      'There is no piece'
    end
  end

  def csv_files_piece_link_incorporated(piece)
    if piece.present?
      link_to 'Incorporated Freecen CSV Files', freecen_csv_files_path, class: 'btn   btn--small', title: 'Csv files for this Piece'
    else
      'There is no piece'
    end
  end

  def vld_files_piece_link(piece)
    if piece.present?
      link_to 'Freecen VLD Files', freecen1_vld_files_path, class: 'btn   btn--small', title: 'VLD files for this Piece'
    else
      'There is no piece'
    end
  end

  def individual_civil_link(parish)
    link_to "#{parish.name} #{parish.add_hamlet_township_names}", freecen2_civil_parish_path(parish.id)
  end

  def place_link(place)
    if place.present?
      link_to "#{place.place_name}", freecen2_place_path(place.id), class: 'btn   btn--small', title: ' Displays all of the information about the place to which this Sub District (Piece) is linked'
    else
      'There is no place'
    end
  end

  def piece_year(piece, year)
    freecen2_piece = Freecen2Piece.find_by(chapman_code: session[:chapman_code], name: piece, year: year)
    if freecen2_piece.present? && freecen2_piece.year == year
      link_to 'Yes', freecen2_piece_path(freecen2_piece.id, type: @type), method: :get, class: 'btn   btn--small', title: ' Displays all of the information about this specific Sub District (Piece)'
    else
      'No'
    end
  end

  def piece_index_link(chapman_code, year)
    link_to "#{year}", freecen2_pieces_chapman_year_index_path(chapman_code: "#{chapman_code}", year: "#{year}"), method: :get, class: 'btn   btn--small', title: 'List of Sub Districts (Pieces) for this year'
  end

  def piece_record_count(piece)
    count = piece.piece_search_records
    number_with_delimiter(count)
  end
end
