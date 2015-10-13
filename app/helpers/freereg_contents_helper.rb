module FreeregContentsHelper
  def county_content(chapman_code)
    page = Refinery::CountyPages::CountyPage.where(:chapman_code => @chapman_code).first
    if page
      raw(page.content)
    else
      ""
    end
  end
  def credit(register)
    if register.credit.present?
      field = register.credit
    else
      field = nil
    end
    field
  end
  def credit_files(files)
    people = Array.new
    field = nil
    if files.present?
      files.each_value do |file|
        people << file["credit_name"] unless file["credit_name"].blank?
      end
      people = people.uniq
      field = people.join(',').to_s
    end
    field
  end
  def number_of_records_in_register(register)
    if session["#{register.id}"].blank?
      individual_files = register.freereg1_csv_files
      actual_records = 0
      individual_files.each do |file|
        actual_records = actual_records + file.freereg1_csv_entries.count
      end
      files = Freereg1CsvFile.combine_files(individual_files)
      records = 0
      datemax = FreeregValidations::YEAR_MIN
      datemin = FreeregValidations::YEAR_MAX
      files.each_pair do |key,value|
        if value.present?
          records = records + value["records"].to_i unless value["records"].blank?
          datemax = value["datemax"].to_i if value["datemax"].to_i > datemax && value["datemax"].to_i < FreeregValidations::YEAR_MAX
          datemin = value["datemin"].to_i if value["datemin"].to_i < datemin
        end
      end
      session["#{register.id}"]= Array.new
      session["#{register.id}"][0] = records
      session["#{register.id}"][1] = datemin
      session["#{register.id}"][2] = datemax
      field = actual_records
    else
      field = actual_records
    end
    field 
  end
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
