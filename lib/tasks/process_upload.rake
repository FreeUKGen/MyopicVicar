task :process_upload => :environment do
  puts "Processing upload."
  @image_upload = ImageUpload.find(ENV['UPLOAD_ID'])
  @image_upload.process_upload
end
