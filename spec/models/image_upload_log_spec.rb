require 'spec_helper'

describe ImageUploadLog do

  SIMPLE_DIR = '/home/benwbrum/dev/freeukgen/mvuploads/simpletest'
  
  it "should create a logfile when its created" do
    iu = ImageUpload.create(:path => "/tmp")
    iu.image_upload_log.last.should be_an_instance_of(ImageUploadLog)
    fn = iu.image_upload_log.last.file
    iu.image_upload_log.last.read.should match /Created/
  end

  it "should be accessible from child objects" do
    # set up the object heirarchy
    iu = ImageUpload.create(:path => SIMPLE_DIR)
    my_log = iu.image_upload_log.last
    
    iu.copy_to_originals_dir
    iu.process_originals_dir(iu.originals_dir)

    
    iu.image_dir.last.log("LOGGEDFROMDIR")
    my_log.read.should match /LOGGEDFROMDIR/
    
    iu.image_dir.last.image_file.last.log("LOGGEDFROMFILE")
    my_log.read.should match /LOGGEDFROMFILE/
  end
  


end
