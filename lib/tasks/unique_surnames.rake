
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
  require 'unique_forename'
  puts 'Starting forenames'
  UniqueForename.delete_all
  grouped_forenames =  BestGuess.group(:GivenName).count(:GivenName)
  grouped_forenames.each { |rec| UniqueForename.create(Name: rec[0], count: rec[1])  }
  #n = 0
  #BestGuess.distinct.pluck(:GivenName).sort.each do |forename|
   # n += 1
    #records = BestGuess.where(GivenName: forename).count
    #puts "#{forename}, #{records}"
    #UniqueForename.create(:Name => forename, :count => records)
  #end
  puts "Finished forenames"
end

task :unique_individual_forenames => :environment do
  require 'unique_forenames'
  puts 'Starting individual forenames'
  UniqueForename.delete_all
  n = 0
  BestGuess.distinct.pluck(:GivenName).sort.each do |forename|
    #n += 1
    names = forename.split(/[^[[:word:]]]+/)
    names.each do |thisname|
      if thisname.length > 1
        if UniqueForename.find_by(Name: thisname) == nil
          records = BestGuess.where(GivenName: thisname).count
          puts "#{thisname}, #{records}"
          UniqueForename.create(:Name => thisname, :count => records)
        end
      end
    end
  end
  puts "Finished individual forenames"
end
