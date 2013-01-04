namespace :s3bucket do
  task :import => :environment do
    s3_bucket_id = ENV['S3_BUCKET_ID']
    dir_name = ENV['DIR_NAME']
    upload_id = ENV['UPLOAD_ID']
    @s3bucket = S3bucket.find(s3_bucket_id) # s3 bucket id
    @s3bucket.flush_to_slash_tmp(dir_name, upload_id)
    ul = Upload.find(upload_id)
    ul.status = "new"
    ul.save
    puts "Task create_and_import complete."
  end
end
