module Freecen2SiteStatisticsHelper
  def data_integrity_flag(census, check_num)

    #1) Search records = Individuals
    #2) Online VLD files = VLD files
    #3) CSV files >= CSV Files incorporated
    #4) CSV entries >= CSV entries incorporated
    #5) Individuals = VLD entries + CSV entries incorporated

    flag = ''
    case check_num
    when '1'
      unless @county_stats[census][:search_records] == @county_stats[census][:individuals] then flag = '*¹' end
    when '2'
      unless @county_stats[census][:vld_files_on_line] == @county_stats[census][:vld_files] then flag = '*²' end
    when '3'
      unless @county_stats[census][:csv_files] >= @county_stats[census][:csv_files_incorporated] then flag = '*³' end
    when '4'
      unless @county_stats[census][:csv_entries] >= @county_stats[census][:csv_entries_incorporated] then flag = '*⁴' end
    when '5'
      unless @county_stats[census][:individuals] == @county_stats[census][:vld_entries] + @county_stats[census][:csv_entries_incorporated] then flag = '*⁵' end
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
    when 'search_records'
      display_cell = cell.to_s + data_integrity_flag(census, '1')
    when 'vld_files_on_line'
      display_cell = cell.to_s + data_integrity_flag(census, '2')
    when 'csv_files'
      display_flagged = cell.to_s + data_integrity_flag(census, '3')
      if cell > 0
        display_cell = link_to "#{display_flagged}", freecen_csv_files_path(order: 'alphabetic', stats_year: year),:title=>'List details', method: :get
      else
        display_cell = display_flagged
      end
    when 'csv_entries'
      display_cell = cell.to_s + data_integrity_flag(census, '4')
    when 'individuals'
      display_cell = cell.to_s + data_integrity_flag(census, '5')
    else
      display_cell = cell
    end
    display_cell
  end
end
