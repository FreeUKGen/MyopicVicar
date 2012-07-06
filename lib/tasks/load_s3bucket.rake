desc "Initialize the fbmd s3 bucket"
task :fbmd_s3bucket => :environment do

  # consider deleting old buckets  
  require 'set'

  set = Set.new
  File.foreach(ARGV[1]) do |line|
    set << File.dirname(line)
  end
  bucket = S3bucket.create(:name => 'fbmd-images', :prefixes => set.to_a)
  p bucket

  
end
