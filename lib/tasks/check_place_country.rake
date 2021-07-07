desc "Remove place field from Freecen2Place"
require 'chapman_code'


task :remove_place_fields => :environment do |t, args|
  start = Time.now
  places = 0
  Freecen2Place.not_disabled.no_timeout.each do |place|
    places = places + 1
    p places if (places / 1000) * 1000 == places
    place.ucf_list = nil
    place.records = nil
    place.datemin = nil
    place.datemax = nil
    place.daterange = nil
    place.transcribers = nil
    place.contributors = nil
    place.open_record_count = nil
    place.unique_surnames = nil
    place.unique_forenames = nil
    result = place.save
  end

end
