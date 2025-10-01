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
      a = link_to 'Back to district', districts_select_district_path(id: link_hash[:district].id)
    end
    return a
  end

  def district_link_or_name(district, search_record, search_query)
    return search_record[:District] unless district.present?
    
    if district.valid?
      link_to(
        titleize_string(search_record[:District]), 
        district_friendly_url_path(
          district.district_friendly_url, 
          id: district.DistrictNumber, 
          search_id: search_query.id
        )
      )
    else
      district.DistrictName
    end
  end

  def district_link_or_name_id(district, search_record, search_id)
    return search_record[:District] unless district.present?
    
    if district.valid?
      link_to(
        titleize_string(search_record[:District]), 
        district_friendly_url_path(
          district.district_friendly_url, 
          id: district.DistrictNumber,
          entry_id: search_record.RecordNumber,
          search_id: search_id
        )
      )
    else
      district.DistrictName
    end
  end
end