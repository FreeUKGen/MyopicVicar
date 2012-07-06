require 'spec_helper'

TEST_BUCKET = 'unit-tests'

describe S3bucket do
  it "should parse a directory from a key" do
    S3bucket.dir_from_key("foo/bar/baz/quux.txt").should eq("foo/bar/baz/")
  end
  
  it "should get directories" do
    setup
    b = S3bucket.new(:name => TEST_BUCKET)
    b.directories.count.should eq(3)
  end
end


def setup
  c = Fog::Storage.new(:provider => 'AWS')
  bucket = c.directories.get(TEST_BUCKET)
  bucket.files.create(:key => 'FreeTEST/File0.txt', :body => "test", :public => true)
  bucket.files.create(:key => 'FreeTEST/Dir1/File1.txt', :body => "test", :public => true)
  bucket.files.create(:key => 'FreeTEST/Dir1/File2.txt', :body => "test", :public => true)
  bucket.files.create(:key => 'FreeTEST/Dir2/File3.txt', :body => "test", :public => true)
  bucket.files.create(:key => 'FreeTEST/Dir2/File4.txt', :body => "test", :public => true)
  
end