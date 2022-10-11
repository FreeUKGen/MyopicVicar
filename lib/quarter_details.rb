module QuarterDetails
  def self.quarters
    {
      march: 1,
      june: 2,
      september: 3,
      december: 4
    }
  end

  def self.quarters_csv
    {
      Mar: 1,
      Jun: 2,
      Sep: 3,
      Dec: 4
    }
  end

  def self.quarter_month record_quarter_number
    quarters.key((record_quarter_number - 1)%4 + 1)
  end

  def self.quarter_month_csv record_quarter_number
    quarters_csv.key((record_quarter_number - 1)%4 + 1)
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

  def self.quarter_csv record_quarter_number
    "#{quarter_month_csv(record_quarter_number)} #{quarter_year(record_quarter_number)}"
  end
  def self.month_hash
    {
      "01" => "January",
      "02" => "February",
      "03" => "March",
      "04" => "April",
      "05" => "May",
      "06" => "June",
      "07" => "July",
      "08" => "August",
      "09" => "September",
      "10" => "October",
      "11" => "November",
      "12" => "December",
    }
  end

  def self.quarter_hash
    {
      "1" => "Jan to Mar",
      "2" => "Apr to Jun",
      "3" => "Jul to Sept",
      "4" => "Oct to Dec",
    }
  end
end