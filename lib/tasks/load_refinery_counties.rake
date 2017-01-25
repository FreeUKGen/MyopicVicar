require 'chapman_code'

task :load_refinery_counties => :environment do
  #  load_syndicates
  load_counties

end

def load_counties
  position = 1
  codes = ChapmanCode.merge_countries
  codes.each_pair do |name, code|
    Refinery::CountyPages::CountyPage.create( :name => name, :chapman_code => code, :position => position )
    position = position+1
  end
end
