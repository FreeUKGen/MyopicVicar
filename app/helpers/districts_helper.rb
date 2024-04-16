module DistrictsHelper
  def show_page_back_link(link_to_hash = {})
    link_hash = link_to_hash
    logger.warn(link_hash)
    case
    when link_hash[:search_query].present? && !link_hash[:search_record].present?
      a = link_to 'Back to search results', search_query_path(link_hash[:search_query]), class: " btn   btn--small"
    when link_hash[:search_record].present?
      a = link_to 'Back to entry', friendly_bmd_record_details_path(link_hash[:search_query].id,link_hash[:search_record].id, link_hash[:search_record].friendly_url, search_entry: link_hash[:search_record].RecordNumber), class: " btn   btn--small"
    when link_hash[:district].present? && !link_hash[:search_query].present?
      a= link_to 'Back', "/districts/districts_list?params=#{link_hash[:district].DistrictName.first}", class: " btn   btn--small"
    end
    return a
  end
end