namespace :s3bucket do
  task :listen, [:bucket_dir, :upload_id] => :environment do |t, args|
    dir_name = args.bucket_dir
    upload_id = args.upload_id
    FileUtils.mkdir_p "/tmp/myopicvicar/fbmd-images/#{dir_name}"
    files = []
    Listen.to("/tmp/myopicvicar/fbmd-images/#{dir_name}") do |modified, added, removed|
      files << added unless added.empty?
      puts "files is #{files}"
      puts "number of files downloaded #{files.length}"
      u = Upload.find(upload_id)
      u.downloaded = files.length
      u.save
    end
  end

  task :import, [:bucket_id, :bucket_dir, :upload_id] => :environment do |t, args|
    s3_bucket_id = args.bucket_id
    dir_name = args.bucket_dir
    upload_id = args.upload_id
    @s3bucket = S3bucket.find(s3_bucket_id)
    @s3bucket.bucket_total_files(dir_name, upload_id)
    @s3bucket.flush_to_slash_tmp(dir_name)
    ul = Upload.find(upload_id)
    ul.status = "new"
    ul.save
    puts "Successfully imported data."
  end
end
