module Freecen2SiteStatisticsHelper
  def data_integrity_checks(census)

    #1) Search records = Individuals
    #2) Online VLD files = VLD files
    #3) CSV files >= CSV Files incorporated
    #4) CSV records >= CSV records incorporated
    #5) Individuals = VLD records + CSV records incorporated

    @num_issues = 0
    @search_records_flag =''
    @vld_files_on_line_flag = ''
    @csv_files_flag = ''
    @csv_entries_flag = ''
    @individuals_flag = ''
    if @county_stats[census][:search_records] != @county_stats[census][:individuals]
      @search_records_flag = '*¹'
      @num_issues += 1
    end
    if @county_stats[census][:vld_files_on_line] != @county_stats[census][:vld_files]
      @vld_files_on_line_flag = '*²'
      @num_issues += 1
    end
    if @county_stats[census][:csv_files] < @county_stats[census][:csv_files_incorporated]
      @csv_files_flag = '*³'
      @num_issues += 1
    end
    if @county_stats[census][:csv_entries] < @county_stats[census][:csv_entries_incorporated]
      @csv_entries_flag = '*⁴'
      @num_issues += 1
    end
    if @county_stats[census][:individuals] != @county_stats[census][:vld_entries] + @county_stats[census][:csv_entries_incorporated]
      @individuals_flag = '*⁵'
      @num_issues += 1
    end
  end

  def site_statistics_drilldown(cell, census, data_type)
    if census == :total
      year = 'all'
    else
      year = census
    end
    case data_type
    when 'search_records'
      display_cell = cell.to_s + @search_records_flag
    when 'vld_files_on_line'
      display_cell = cell.to_s + @vld_files_on_line_flag
    when 'csv_files'
      display_flagged = cell.to_s + @csv_files_flag
      if cell > 0
        if @num_issues > 0
          display_cell = link_to "#{display_flagged}", freecen_csv_files_path(order: 'alphabetic', stats_year: year, select_recs: 'all'),:title=>'List details', method: :get, style: "color: red"
        else
          display_cell = link_to "#{display_flagged}", freecen_csv_files_path(order: 'alphabetic', stats_year: year, select_recs: 'all'),:title=>'List details', method: :get
        end
      else
        display_cell = cell
      end
    when 'csv_files_incorporated'
      if cell > 0
        if @num_issues > 0
          display_cell = link_to "#{cell}", freecen_csv_files_path(order: 'alphabetic', stats_year: year, select_recs: 'incorporated'),:title=>'List details', method: :get, style: "color: red"
        else
          display_cell = link_to "#{cell}", freecen_csv_files_path(order: 'alphabetic', stats_year: year, select_recs: 'incorporated'),:title=>'List details', method: :get
        end
      else
        display_cell = cell
      end
    when 'csv_entries'
      display_cell = cell.to_s + @csv_entries_flag
    when 'individuals'
      display_cell = cell.to_s + @individuals_flag
    else
      display_cell = cell
    end
    display_cell
  end
end
