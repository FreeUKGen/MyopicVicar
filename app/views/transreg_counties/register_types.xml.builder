xml.RegisterTypes do
	@types.each do |registertype|
	 	xml.registertype do
			xml.Type registertype[1]
			xml.Description registertype[0]
		end
	end
end
