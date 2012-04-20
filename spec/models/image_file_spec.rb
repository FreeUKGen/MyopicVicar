require 'spec_helper'

describe ImageFile do
  ZIP_FILENAME = "/home/benwbrum/dev/freeukgen/mvuploads/heterogenoustest/Flintshire 1861.zip" 
  IMAGE_FILENAME = '/home/benwbrum/dev/freeukgen/mvuploads/heterogenoustest/4143523_01206.jpg'
  PDF_FILENAME = "/home/benwbrum/dev/freeukgen/mvuploads/heterogenoustest/SSCens Tutorial_Spread_1p.pdf"


  it "should test for zipfiles" do
    ImageFile.is_image?(ZIP_FILENAME).should eq false
  end
  it "should test for pdf files" do
    ImageFile.is_image?(PDF_FILENAME).should eq false
    
  end
  it "should test for images files" do
    ImageFile.is_image?(IMAGE_FILENAME).should eq true
    
  end
end
