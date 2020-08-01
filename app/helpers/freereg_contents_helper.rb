module FreeregContentsHelper
  require 'freereg_options_constants'
  def county_content(page)
    if page
      raw(page.content)
    else
      ''
    end
  end

  def clear(register)
    session.delete("#{register.id}")
  end

  def add_blank(field)
    if field.blank?
      field = ' '
    end
    field
  end

  def amended(date)
    if date.nil?
      field = ' '
    else
      field = date[3, 8]
    end
    field
  end

  def churches_for_place?(place)
    result = place.churches.count.zero? ? false : true
    result
  end

  def registers_for_church?(church)
    result = church.registers.count.zero? ? false : true
    result
  end

  def gap_record_type(gap)
    return 'All' if gap == 'All'
    RecordType.display_name(gap)
  end

  def locate(latitude, longitude)
    #    link_to 'Location', "https://www.google.com/maps/@?api=1&map_action=map&center=#{latitude},#{longitude}&zoom=13", target: :_blank, title: 'Shows the location on a Google map'
    link_to 'Location', "https://www.google.com/maps/search/?api=1&query=#{latitude},#{longitude}", target: :_blank, class: 'btn   btn--small', title: 'Shows the location on a Google map in a new tab'
  end
end
