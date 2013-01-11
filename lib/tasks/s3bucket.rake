namespace :s3bucket do
  task :import => :environment do
    s3_bucket_id = ENV['S3_BUCKET_ID']
    dir_name = ENV['DIR_NAME']
    upload_id = ENV['UPLOAD_ID']
    @s3bucket = S3bucket.find(s3_bucket_id) # s3 bucket id
    @s3bucket.bucket_total_files(dir_name, upload_id)
    @s3bucket.flush_to_slash_tmp(dir_name)
    ul = Upload.find(upload_id)
    ul.status = "new"
    ul.save
    puts "Successfully imported data."
  end

  task :listen => :environment do
    dir_name = ENV['DIR_NAME']
    upload_id = ENV['UPLOAD_ID']
    FileUtils.mkdir_p "/tmp/myopicvicar/fbmd-images/#{dir_name}"
    files = []
    Listen.to("/tmp/myopicvicar/fbmd-images/#{dir_name}") do |modified, added, removed|
      files << added
      puts "files is #{files}"
      puts "number of files downloaded #{files.length}"
      u = Upload.find(upload_id)
      u.downloaded = files.length
      u.save
    end
  end
end
