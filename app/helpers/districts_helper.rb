module DistrictsHelper
  def show_page_back_link(link_to_hash = {})
    link_hash = link_to_hash
    logger.warn(link_hash)
    case
    when link_hash[:search_query].present? && !link_hash[:search_record].present?
      back_opts = {}
      back_opts[:page] = link_hash[:page] if link_hash[:page].present?
      back_opts[:results_per_page] = link_hash[:results_per_page] if link_hash[:results_per_page].present?
      a = link_to "#{app_icons[:left_arrow_pink]} Back to search results".html_safe,
                  search_query_path(link_hash[:search_query], back_opts)
    when link_hash[:search_record].present?
      sr = link_hash[:search_record]
      sq = link_hash[:search_query]
      back_url =
        if sq.present?
          friendly_bmd_record_details_path(sq.id, sr.RecordNumber, sr.friendly_url, search_entry: sr.RecordNumber, record_hash: sr.record_hash)
        else
          friendly_bmd_record_details_non_search_path(sr.RecordNumber, sr.friendly_url, search_entry: sr.RecordNumber, record_hash: sr.record_hash)
        end
      a = link_to "#{app_icons[:left_arrow_pink]} Back to entry".html_safe, back_url
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

  def district_link_or_name(district, search_record, search_query, page: nil, results_per_page: nil)
    return search_record[:District] unless district.present?
    
    if district.valid?
      path_opts = {
        id: district.DistrictNumber,
        friendly: district.district_friendly_url,
        search_id: search_query.id
      }
      path_opts[:page] = page if page.present?
      path_opts[:results_per_page] = results_per_page if results_per_page.present?
      link_to(
        titleize_string(search_record[:District]),
        district_friendly_url_path(path_opts)
      )
    else
      district.DistrictName
    end
  end

  def district_link_or_name_id(district, search_record, search_id, page: nil, results_per_page: nil)
    return search_record[:District] unless district.present?
    
    if district.valid?
      path_opts = {
        id: district.DistrictNumber,
        friendly: district.district_friendly_url,
        entry_id: search_record.RecordNumber,
        search_id: search_id
      }
      path_opts[:page] = page if page.present?
      path_opts[:results_per_page] = results_per_page if results_per_page.present?
      link_to(
        titleize_string(search_record[:District]),
        district_friendly_url_path(path_opts)
      )
    else
      district.DistrictName
    end
  end
end