require 'spec_helper'

describe ImageUpload do
#  pending "basic stuff"
  
  it "can be instantiated" do
    ImageUpload.new.should be_an_instance_of(ImageUpload)
  end
  
  it "should be persisted" do
    ImageUpload.create(:path => '/tmp').should be_persisted
  end
  
  it "should persist an upload directory" do
    iu = ImageUpload.new
    iu.path = "/tmp"
    iu.save!
    id = iu.id
    iu2 = ImageUpload.find(id)
    iu2.path.should eq("/tmp")
  end
  
  
  it "should check for valid upload directory" do
    iu = ImageUpload.new
    iu.path = "foo"
    iu.should be_invalid
    iu.path = '/tmp'
    iu.should be_valid
    
    TMPDIR = "/tmp/MyopicVicarTest"

    iu.path = TMPDIR
    system("mkdir -p #{TMPDIR}")
    system("chmod ugo+rx #{TMPDIR}")
    iu.should be_valid

    system("chmod ugo-rx #{TMPDIR}")
    iu.should be_invalid
    system("chmod ugo+x #{TMPDIR}")
    iu.should be_invalid
    system("chmod ugo-x #{TMPDIR}")
    system("chmod ugo+r #{TMPDIR}")
    iu.should be_invalid
    system("chmod ugo+rx #{TMPDIR}")
    iu.should be_valid
    system("rmdir #{TMPDIR}")
    iu.should be_invalid
  end
  
  
end
