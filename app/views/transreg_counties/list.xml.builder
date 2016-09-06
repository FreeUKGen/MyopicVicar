xml.CountiesTable do
  if @counties.present?
	@counties.each do |county|
	 	xml.county do
			xml.ChapmanCode county.chapman_code
			xml.Description county.county_description
			xml.Notes county.county_notes
		end
	end
  end
end
