xml.PlacesTable do
	@places.each do |place|
	 	xml.place do
			xml.ChapmanCode place.chapman_code
			xml.PlaceName   place.place_name
			xml.Country     place.country
			xml.CountyName  place.county
			xml.Notes       place.place_notes
		end
	end
end
