module DistrictsHelper
  def show_page_back_link(link_to_hash = {})
    link_hash = link_to_hash
    logger.warn(link_hash)
    case
    when link_hash[:search_query].present? && !link_hash[:search_record].present?
      a = link_to "#{app_icons[:left_arrow_pink]} Back to search results".html_safe, search_query_path(link_hash[:search_query])
    when link_hash[:search_record].present?
      a = link_to "#{app_icons[:left_arrow_pink]} Back to entry".html_safe, friendly_bmd_record_details_path(link_hash[:search_query].id,link_hash[:search_record].id, link_hash[:search_record].friendly_url, search_entry: link_hash[:search_record].RecordNumber)
    when link_hash[:district].present? && !link_hash[:search_query].present?
      a= link_to "#{app_icons[:left_arrow_pink]} Back to overview".html_safe, "/districts/districts_overview"
    else
      a = link_to "#{app_icons[:left_arrow_pink]} Back to overview".html_safe, "/districts/districts_overview"
    end
    return a
  end

  def show_back_to_district_link(link_to_hash = {})
    link_hash = link_to_hash
    logger.warn(link_hash)
    case
    when link_hash[:district].present?
      a = link_to "#{app_icons[:left_arrow_pink]} Back to district", districts_select_district_path(id: link_hash[:district].id)
    end
    return a
  end
end