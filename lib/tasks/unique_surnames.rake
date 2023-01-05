
task :unique_surnames => :environment do
  require 'unique_surnames'
  puts 'Starting surnames'
  UniqueSurname.delete_all
  n = 0
  BestGuess.distinct.pluck(:Surname).sort.each do |surname|
    n += 1
    records = BestGuess.where(Surname: surname).count
    puts "#{surname}, #{records}"
    UniqueSurname.create(:Name => surname, :count => records)
  end
  puts "Finished surnames"
end

task :unique_forenames => :environment do
  require 'unique_forenames'
  puts 'Starting forenames'
  UniqueForename.delete_all
  n = 0
  BestGuess.distinct.pluck(:GivenName).sort.each do |forename|
    n += 1
    records = BestGuess.where(GivenName: forename).count
    puts "#{forename}, #{records}"
    UniqueForename.create(:Name => forename, :count => records)
  end
  puts "Finished forenames"
end
