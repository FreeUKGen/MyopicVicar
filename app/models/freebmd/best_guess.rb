class BestGuess < ActiveRecord::Base
  establish_connection FREEBMD_DB
  self.pluralize_table_names = false
  self.table_name = 'BestGuess'
  has_many :BestGuessMarriage, foreign_key: :RecordTypeID#, :volume, :page, :QuarterNumber
  extend SharedSearchMethods

  def friendly_url
    particles = []
    # first the primary names
    particles << self.GivenName if self.GivenName
    particles << self.Surname if self.Surname

    # then the record types
    particles << RecordType::display_name(self.RecordTypeID)
    # then county name
    #particles << ChapmanCode.name_from_code(chapman_code)
    # then location
    #particles << self.place.place_name if self.place.place_name
    # finally date
    #particles << search_dates.first
    # join and clean
    friendly = particles.join('-')
    friendly.gsub!(/\W/, '-')
    friendly.gsub!(/-+/, '-')
    friendly.downcase!
  end
end