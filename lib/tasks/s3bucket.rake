namespace :s3bucket do
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
