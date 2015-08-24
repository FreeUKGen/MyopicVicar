module Freereg1CsvFilesHelper

  def get_place(county,name)
    place = Place.where(:chapman_code => county, :place_name => name).first
  end

end
