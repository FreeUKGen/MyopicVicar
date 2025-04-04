class Coverage < FreebmdDbBase
  self.pluralize_table_names = false
  self.table_name = 'Coverage'

  def quarter_number_event_to_quarter
    (self.QuarterNumberEvent - 1) / 3
  end

  def quarter_number_event_to_event_type
    self.QuarterNumberEvent % 3
  end

  #def quarter_number_event_to_year
  #  quarter_number = self.quarter_number_event_to_quarter
  #  year = (quarter_number / 4).to_i + 1837
  #  year
  #end

  def quarter_number_event_started
    (self.Percentage > 0)
  end

  def quarter_number_event_unfinished
    (self.Percentage < 100)
  end

  def quarter_number_to_string(quarter_number)
    case quarter_number
    when 1
      "Mar"
    when 2
      "Jun"
    when 3
      "Sep"
    when 4
      "Dec"
    else
      "Error: "+quarter_number.to_s
    end
  end

  def event_type_to_string(event_type)
    case event_type
    when 0
      "Marriages"
    when 1
      "Births"
    when 2
      "Deaths"
    end
  end

end
