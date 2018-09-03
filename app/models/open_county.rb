class OpenCounty
  include Mongoid::Document
  field :chapman_code, type: String
  field :record_count, type: Integer
  field :place_count, type: Integer
  
  
  def self.rebuild_open_counties
    OpenCounty.delete_all
    county_stats = {}
    Place.where(:open_record_count.gt => 0).order(:chapman_code => 1).no_timeout.each do |place|
      open_county = county_stats[place.chapman_code] || OpenCounty.new(:chapman_code => place.chapman_code, :record_count => 0, :place_count => 0)
      open_county.record_count += place.open_record_count
      open_county.place_count += 1 
      county_stats[place.chapman_code] = open_county
    end
    county_stats.values.each { |open_county| open_county.save! }
  end
end
