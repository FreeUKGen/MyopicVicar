module QuarterDetails
  def self.quarters
    {
      march: 1,
      june: 2,
      september: 3,
      december: 4
    }
  end

  def self.quarter_month record_quarter_number
    quarters.key((record_quarter_number - 1)%4 + 1)
  end

  def self.quarter_year record_quarter_number
    (record_quarter_number - 1)/4 + 1837
  end

  def self.quarter record_quarter_number
    (record_quarter_number - 1)%4 + 1
  end

  def self.quarter_human record_quarter_number
    #{}"#{QuarterDetails.quarters.key((search_record[:QuarterNumber]-1)%4 + 1).upcase} #{(search_record[:QuarterNumber]-1)/4 + 1837}"
    "#{quarter_month(record_quarter_number).upcase} #{quarter_year(record_quarter_number)}"
  end
end