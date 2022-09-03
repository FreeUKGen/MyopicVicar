task :update_freecen2_place_data_present, [:file] => [:environment] do |t, args|
  # recomputes data_present and cen_date_years and refreshes freecen2_place_cache for a freecen2_place id
  # e.g.   rake update_freecen2_place_data_present[5fc6dda2f4040beff4820fba]
  p "Starting #{args.file}"
  place = Freecen2Place.where(_id: args.file).first
  if place.blank?
    p 'Place does not exist'
  else
    p place.inspect
    cen_data = place.search_records.distinct(:record_type)
    p cen_data.inspect
    if cen_data.present?
      place.update_attributes(data_present: true, cen_data_years: cen_data)
    else
      place.update_attributes(data_present: false, cen_data_years: cen_data)
    end
    Freecen2PlaceCache.refresh(place.chapman_code)
  end
  p 'finished'
end
