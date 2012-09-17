task :import => :environment do
  s3_bucket_id = ENV['S3_BUCKET_ID']
  dir_name = ENV['DIR_NAME']
  @s3bucket = S3bucket.find(s3_bucket_id)
  @s3bucket.flush_to_slash_tmp(dir_name)
  cr = Upload.create(:upload_path => @s3bucket.slash_tmp_dir(dir_name), :name => dir_name)
  puts "Upload complete."
end
