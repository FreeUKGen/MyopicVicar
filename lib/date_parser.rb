
module DateParser
  MONTHS = {
    'Jan' => '01',
    'Feb' => '02',
    'Mar' => '03',
    'Apr' => '04',
    'May' => '05',
    'Jun' => '06',
    'Jul' => '07',
    'Aug' => '08',
    'Sep' => '09',
    'Oct' => '10',
    'Nov' => '11',
    'Dec' => '12'
  }

  def self.searchable(verbatim)
    return verbatim unless verbatim
    unless verbatim.match(/\d\d/)  #at least most of a year
      return verbatim
    end
    if verbatim.match(/(\S+)\s(\S+)\s(\S+)/)
      d = $1
      vm = $2
      vy = $3
    elsif verbatim.match(/\s?(\S+)\s(\S+)/)
      d = '*'
      vm = $1
      vy = $2
    elsif verbatim.match(/(\d\d\d\d)/)
      d = '*'
      vm = '*'
      vy = $1
    elsif verbatim.match(/(\d\d\d_)/)
      d = '*'
      vm = '*'
      vy = $1
    elsif verbatim.match(/(\d\d__)/)
      d = '*'
      vm = '*'
      vy = $1
    else
      return verbatim
    end

    # handle unclear years
    if vy.match(/(\d\d\d)[_*]/)
      vy = $1 + '5'
    end
    if vy.match(/(\d\d)__/) || vy.match(/(\d\d)\*/) 
      vy = $1 + '50'
    end

    # handle split years
    if vy.match(/(\d+)\//)
      y = $1.to_i + 1
    else
      y = vy
    end

    # convert month names to numbers
    if MONTHS[vm]
      m = MONTHS[vm]
    else
      m = vm
    end

    # zero-pad
    if d.match(/\b\d\b/)
      d = "0"+d
    end

    "#{y}-#{m}-#{d}"
  end

  def self.start_search_date(year)
    # zero-pad for completionist users inputting three-digit years
    return year.to_s.rjust(4,"0")
  end

  def self.end_search_date(year)
    # make the year inclusive
    next_year = year + 1
    # calculate new year
    if next_year < 1753
      "#{next_year}-03-25"
    else
      "#{year}-12-31"
    end
  end

end
