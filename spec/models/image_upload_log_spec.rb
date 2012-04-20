require 'spec_helper'

describe ImageUploadLog do

  it "should create a logfile when its created" do
    iu = ImageUpload.create(:path => "/tmp")
    iu.image_upload_log.last.should be_an_instance_of(ImageUploadLog)
    fn = iu.image_upload_log.last.file
    iu.image_upload_log.last.read.should match /Created/
  end


end
