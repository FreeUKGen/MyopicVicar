module PlacesHelper

  def first_year_in_register(register)
    if session["#{register.id}"][1] == FreeregValidations::YEAR_MAX
      field = ""
    else
      field = session["#{register.id}"][1]
    end
  end
  def last_year_in_register(register)
    if session["#{register.id}"][2] == FreeregValidations::YEAR_MIN
      field = ""
    else
      field = session["#{register.id}"][2]
    end
  end
  def clear(register)
    session.delete("#{register.id}")
  end
  def active(yes)
    field = "All"
    field = "Active" if yes
    field
  end

  def place_name_from_ucf_list(file)
    filename = Freereg1CsvFile.find_by(_id: file.to_s)
    file_name = filename.present? ? filename.file_name : 'None'
    file_name
  end

  def place_format_ucf_list(record)
    search = SearchRecord.find_by(_id: record.to_s)
    entry = search.freereg1_csv_entry if search.present?
    if entry.present?
      link_to "#{entry.id.to_s}", freereg1_csv_entry_path(entry.id.to_s, from: 'place'), method: :get
    end
  end
end
