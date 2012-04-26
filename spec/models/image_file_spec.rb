require 'spec_helper'

describe ImageFile do
  ZIP_FILENAME = "/home/benwbrum/dev/freeukgen/mvuploads/heterogenoustest/Flintshire 1861.zip" 
  IMAGE_FILENAME = '/home/benwbrum/dev/freeukgen/mvuploads/heterogenoustest/4143523_01206.jpg'
  PDF_FILENAME = "/home/benwbrum/dev/freeukgen/mvuploads/heterogenoustest/SSCens Tutorial_Spread_1p.pdf"
  THUMB_FILENAME = '/home/benwbrum/dev/freeukgen/mvuploads/heterogenoustest/4143523_01206_thumb.png'


  it "should test for zipfiles" do
    ImageFile.is_image?(ZIP_FILENAME).should eq false
  end
  it "should test for pdf files" do
    ImageFile.is_image?(PDF_FILENAME).should eq false
    
  end
  it "should test for images files" do
    ImageFile.is_image?(IMAGE_FILENAME).should eq true
  end
  
#  it "should create a thumbnail" do
#    i = ImageFile.create(:name => IMAGE_FILENAME)
#    File.exists?(THUMB_FILENAME).should be_true
#  end
  
  it "should read height and width" do
    i = ImageFile.create(:name => IMAGE_FILENAME)
    i.height.should eq 3162
    i.width.should eq 4038
  end
  
end
