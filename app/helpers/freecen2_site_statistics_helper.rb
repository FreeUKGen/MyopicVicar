module Freecen2SiteStatisticsHelper

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


  def site_statistics_display_cell(cell, census, data_type)
    if census == :total
      year = 'all'
    else
      year = census
    end
    case data_type
    when 'year'
      return link_to "#{year}", stats_index_freecen2_pieces_path(county: @county, sorted_by: 'Most Recent Online', stats_year: year),:title=>'List All Pieces', method: :get
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
