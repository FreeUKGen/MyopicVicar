
task :unique_surnames => :environment do
  puts 'Starting surnames'
  UniqueSurnames.delete_all
  n = 0
  BestGuess.distinct.pluck(:Surname).sort.each do |surname|
    n += 1
    records = BestGuess.where(Surname: surname).count
    puts "#{surname}, #{records}"
    UniqueSurnames.create(:NameID => n, :Name => surname, :LcName => surname.downcase, :count => records)
  end
  puts "Finished surnames"
end

task :unique_forenames => :environment do
  puts 'Starting forenames'
  UniqueForenames.delete_all
  n = 0
  BestGuess.distinct.pluck(:GivenName).sort.each do |forename|
    n += 1
    records = BestGuess.where(GivenName: forename).count
    puts "#{forename}, #{records}"
    UniqueForenames.create(:NameID => n, :Name => forename, :LcName => forename.downcase, :count => records)
  end
  puts "Finished forenames"
end
