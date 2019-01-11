module Freereg1CsvFilesHelper
  def coordinator_index_breadcrumbs
    case
    when session[:syndicate]  && session[:sorted_by] == '; selects files with zero date records then alphabetically by userid and file name'
      breadcrumb :listing_of_zero_year_files
    when session[:county]  && session[:sorted_by] == '; selects files with zero date records then alphabetically by userid and file name'
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
end
