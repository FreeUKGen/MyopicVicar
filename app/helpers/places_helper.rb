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
end
