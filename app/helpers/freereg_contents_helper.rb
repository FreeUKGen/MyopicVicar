module FreeregContentsHelper
  def county_content(page)
    if page
      raw(page.content)
    else
      ""
    end
  end

  def clear(register)
    session.delete("#{register.id}")
  end
  def add_blank(field)
    if field.blank?
      field = " "
    end
    field
  end
  def amended(date)
    if date.nil?
      field = ""
    else
      field = date[3,8]
    end
  end

end
