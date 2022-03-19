desc "Polulate Freecen2_place_sources for issue 1362"
task populate_freecen2_place_sources:  :environment do
  p '*** Started population of Freecen2_place_sources'

  entries_to_insert = []

  source_values = []
  source_values << 'British History Online'
  source_values << 'British Listed Buildings'
  source_values << 'Co Curate'
  source_values << 'Coflein'
  source_values << 'Dusty Docs'
  source_values << 'English Heritage'
  source_values << 'FamilySearch'
  source_values << 'Forebears'
  source_values << 'Gazetteer of British Place Names'
  source_values << 'Genuki'
  source_values << 'Get Outside Ordnance Survey'
  source_values << 'Irish Townlands'
  source_values << 'Mining Data'
  source_values << 'Other'
  source_values << 'The Workhouse'
  source_values << 'UK Genealogy Archives'
  source_values << 'Vision of Britain'
  source_values << 'We Relate'
  source_values << 'Wikipedia'
  source_values << 'Wikishire'

  values_cnt = 0

  source_values.each do |source_value|
    values_cnt += 1
    if Freecen2PlaceSource.find_by(source: source_value).present?
      p "'#{source_value}' already exists"
    else
      entry = Freecen2PlaceSource.new
      entry.source = source_value
      entries_to_insert << entry.attributes
    end
  end

  p "There are #{values_cnt} to insert"

  Freecen2PlaceSource.collection.insert_many(entries_to_insert)

  p "There were #{entries_to_insert.size} inserted"

  place_source_cnt = Freecen2PlaceSource.count

  p "Freecen2_pace_sources now has #{place_source_cnt} records"

  p '*** Finished population of Freecen2_place_sources'
end
