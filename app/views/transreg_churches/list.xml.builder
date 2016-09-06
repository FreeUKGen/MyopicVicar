xml.ChurchesTable do
  if @churches.present?
	@churches.each do |church|
	 	xml.church do
			xml.PlaceName church.place_name
			xml.ChurchName church.church_name
			xml.Location church.location
			xml.Denomination church.denomination
			xml.LastAmended church.last_amended
			xml.Website church.website
			xml.Notes church.church_notes
		end
	end
  end
end
