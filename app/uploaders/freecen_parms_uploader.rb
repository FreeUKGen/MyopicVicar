# encoding: utf-8
class FreecenParmsUploader < CarrierWave::Uploader::Base

  # Choose what kind of storage to use for this uploader:
  storage :file

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
        # "#{Rails.application.config.datafiles}/#{mounted_as}/#{model.userid}/"
#    p "***store_dir=" + "#{Rails.application.config.fc_parms_upload_dir}/"
#    return "#{Rails.application.config.fc_parms_upload_dir}"
    File.join(Rails.root, 'tmp', 'fcparms')
  end
  def cache_dir
    File.join(Rails.root, 'tmp', 'carrierwave')
  end
#  def filename
#    return @filename + '_test' if @filename.present?
#  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process :scale => [50, 50]
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  # def extension_white_list
#  def extension_white_list
#   %w(csv)
#  end
  # end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

end
