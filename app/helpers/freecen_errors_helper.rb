module FreecenErrorsHelper

  def error_county(error)
    parts = error.split('/')
    parts[0]
  end

  def error_file(error)
    parts = error.split('/')
    partsa = parts[1].split(':')
    partsb = partsa[0].split(' ')
    partsb[0].strip
  end

  def error_entry(error)
    parts = error.split('/')
    partsa = parts[1].split(':')
    partsb = partsa[0].split(' ')
    partsb.delete_at(0)
    c = partsb.join(' ')
    c
  end

  def error_message(error)
    parts = error.split('/')
    partsa = parts[1].split(':')
    partsb = partsa[1].split('(')
    partsb[0].strip
  end

  def error_detail(error)
    partsb = error.split('(')
    partsb[1].gsub(')', '')
  end

  def load_error_county(error)
    parts = error.split(' filename:')
    parts[0]
  end

  def load_error_file(error)
    parts = error.split(' filename:')
    partsa = parts[1].split(' ')
    partsa[0].strip
  end

  def load_error_year(error)
    parts = error.split(' filename:')
    partsa = parts[1].split(' ')
    partsb = partsa[1].split(' ')
    partsb[0]
  end

  def load_error_piece(error)
    parts = error.split('piece:')
    partsa = parts[1].split(' ')
    partsa[0]
  end

  def load_error_suffix(error)
    partsa = error.split('suffix:')
    partsb = partsa[1].split('status:')
    partsb[0]
  end

  def load_error_status(error)
    partsb = error.split('status:')
    partsb[1]
  end
end
