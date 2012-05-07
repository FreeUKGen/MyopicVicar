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
 
#  it "should not have an absolute path" do
#    i = ImageFile.create(:name => test_file)
#    p i.name
#    i.name.match(/^\//).should be_false
#  end
 
  it "should create a thumbnail" do
    i = ImageFile.create(:name => test_file)
    File.exists?(i.thumbnail_name).should be_true
  end
  
  it "should read height and width" do
    i = ImageFile.create(:name => test_file)
    i.height.should eq 3162
    i.width.should eq 4038
  end


  BASE_DIR = "/tmp/image_file_spec"

  def test_file
    # quarantine the files
    unless @dir
      Dir.mkdir(BASE_DIR) unless File.exists?(BASE_DIR)
      @dir=File.join(BASE_DIR, Time.now.strftime("%s"))

      FileUtils.rm_rf(@dir)
      Dir.mkdir(@dir)
      FileUtils.cp(IMAGE_FILENAME, @dir)
    end
    File.join(@dir, File.basename(IMAGE_FILENAME))
  end
  
end
