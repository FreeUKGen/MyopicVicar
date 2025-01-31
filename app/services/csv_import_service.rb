class CsvImportService
	def initialize(file_path)
		@file_path = file_path
	end

	def csv_import_and_update_church
		CSV.foreach(@file_path, headers: true) do |row|
      csv_data = row.to_hash
      update_church(csv_data)
    end
	end

	def find_place(data)
		Place.find_by(place_name: data['place_name'], chapman_code: data['chapman_code'])
	end

	def find_church(place,data)
		place.churches.find_by(church_name: data['church_name'])
	end

	def update_church(data)
    place = find_place(data)
    return unless place

    church = find_church(place, data)
    return unless church

    church.update(church_code: data['church_code'])
  end
end