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
end
