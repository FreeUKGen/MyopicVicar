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
    if filename.present?
      link_to "#{filename.file_name}", freereg1_csv_file_path(filename.id.to_s, from: 'place'), method: :get
    else
      'None'
    end
  end
end
