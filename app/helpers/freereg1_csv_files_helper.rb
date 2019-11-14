module Freereg1CsvFilesHelper
  def coordinator_index_breadcrumbs
    p 'coordinator_index_breadcrumbs'
    p session[:place_name]
    if session[:place_name].present?
      breadcrumb :files
    elsif session[:syndicate] && session[:sorted_by] == '; selects files with zero date records then alphabetically by userid and file name'
      breadcrumb :listing_of_zero_year_files
    elsif session[:county] && session[:sorted_by] == '; selects files with zero date records then alphabetically by userid and file name'
      breadcrumb :listing_of_zero_year_files
    else
      breadcrumb :files
    end
  end

  def my_own_files_breadcrumbs
    if session[:sorted_by] == 'Zero years'
      breadcrumb :listing_of_zero_year_files
    else
      breadcrumb :my_own_files
    end
  end

  def can_view_files?(role)
    %w[county_coordinator syndicate_coordinator country_coordinator system_administrator technical
       data_manager volunteer_coordinator documentation_coordinator].include?(role)
  end

  def sorted_by?(sort)
    sort == '; sorted by descending number of errors and then file name'
  end
end
