module Freecen2SiteStatisticsHelper

  def stats_piece_online(piece)
    if piece.status.present?
      status = piece.status_date.present? ? 'Y (' + piece.status_date.to_datetime.strftime("%d/%b/%Y %R") + ')' : 'N'
    else
      status = 'N'
    end
  end

  def stats_csv_files_piece_unincorporated(piece)
    if piece.freecen_csv_files.present?
      files = []
      piece.freecen_csv_files.incorporated(false).order_by(file_name: 1).each do |file|
        if file.userid.blank?
          files << file.file_name + ' ()'
        else
          files << file.file_name + ' (' + file.userid + ')'
        end
      end
      files.size == 0 ? 'none' : files
    else
      'none'
    end
  end

  def stats_csv_files_piece_incorporated(piece)
    if piece.freecen_csv_files.present?
      files = []
      piece.freecen_csv_files.incorporated(true).order_by(file_name: 1).each do |file|
        if file.userid.blank?
          files << file.file_name + ' ()'
        else
          files << file.file_name + ' (' + file.userid + ')'
        end
      end
      files.size == 0 ? 'none' : files
    else
      'none'
    end
  end

  def stats_vld_files_piece(piece)
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
      files.size == 0 ? 'none' : files
    elsif piece.vld_files.present?
      # used for Scotland pieces where there can be multiple files for a single piece
      piece.vld_files
    elsif piece.shared_vld_file.present?
      # used when a file has multiple pieces; usually only occurs with piece has been broken into parts
      file = Freecen1VldFile.find_by(_id: piece.shared_vld_file)
      file.file_name if file.present?
    else
      'none'
    end
  end

  def stats_data_file_type(piece)
    if stats_csv_files_piece_unincorporated(piece) == 'none' && stats_csv_files_piece_incorporated(piece) == 'none' && stats_vld_files_piece(piece) == 'none'
      type = 'n/a'
    else
      type = stats_vld_files_piece(piece) == 'none' ? 'CSVProc' : 'VLD'
    end
  end

  def data_integrity_flag(census, check_num)

    # 1) Search records = Individuals
    # 2) Online VLD files = VLD files
    # 3) CSV files >= CSV Files incorporated
    # 4) CSV records >= CSV records incorporated
    # 5) Individuals = VLD records + CSV records incorporated

    flag = ''
    case check_num
    when '1'
      unless @county_stats[census][:search_records] == @county_stats[census][:individuals] then flag = '*¹' end
    when '2'
      unless @county_stats[census][:vld_files_on_line] == @county_stats[census][:vld_files] then flag = '*²' end
    when '3'
      unless @county_stats[census][:csv_files] >= @county_stats[census][:csv_files_incorporated] then flag = '*³' end
    when '4'
      unless @county_stats[census][:csv_entries] >= @county_stats[census][:csv_individuals_incorporated] then flag = '*⁴' end
    when '5'
      unless @county_stats[census][:individuals] <= @county_stats[census][:vld_entries] + @county_stats[census][:csv_individuals_incorporated] then flag = '*⁵' end
    end
    flag
  end


  def site_statistics_drilldown(cell, census, data_type)
    if census == :total
      year = 'all'
    else
      year = census
    end
    case data_type
    when 'year'
      return link_to "#{year}", list_pieces_freecen2_site_statistics_path(county: @county, sorted_by: 'Piece Number', stats_year: year),:title=>'List Pieces', method: :get
    when 'search_records'
      data_integrity_flag(census, '1') != '' ? display_cell = content_tag(:td, cell.to_s + data_integrity_flag(census, '1'), style: "color: red") : display_cell = content_tag(:td, cell.to_s)
    when 'vld_files_on_line'
      data_integrity_flag(census, '2') != '' ? display_cell = content_tag(:td, cell.to_s + data_integrity_flag(census, '2'), style: "color: red") : display_cell = content_tag(:td, cell.to_s)
    when 'csv_files'
      data_integrity_flag(census, '3') != '' ? display_cell = content_tag(:td, cell.to_s + data_integrity_flag(census, '3'), style: "color: red") : display_cell = content_tag(:td, cell.to_s)
    when 'csv_entries'
      data_integrity_flag(census, '4') != '' ? display_cell = content_tag(:td, cell.to_s + data_integrity_flag(census, '4'), style: "color: red") : display_cell = content_tag(:td, cell.to_s)
    when 'individuals'
      data_integrity_flag(census, '5') != '' ? display_cell = content_tag(:td, cell.to_s + data_integrity_flag(census, '5'), style: "color: red") : display_cell = content_tag(:td, cell.to_s)
    else
      display_cell = content_tag(:td, cell.to_s)
    end
    display_cell
  end
end
