# # Copyright 2012 Trustees of FreeBMD
# # 
# # Licensed under the Apache License, Version 2.0 (the "License");
# # you may not use this file except in compliance with the License.
# # You may obtain a copy of the License at
# # 
# # http://www.apache.org/licenses/LICENSE-2.0
# # 
# # Unless required by applicable law or agreed to in writing, software
# # distributed under the License is distributed on an "AS IS" BASIS,
# # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# # See the License for the specific language governing permissions and
# # limitations under the License.
# # 
# require 'spec_helper'
# 
# TEST_BUCKET = 'unit-tests'
# 
# describe S3bucket do
  # it "should parse a directory from a key" do
    # S3bucket.dir_from_key("foo/bar/baz/quux.txt").should eq("foo/bar/baz/")
  # end
#   
  # it "should get directories" do
    # b = S3bucket.new(:name => TEST_BUCKET)
    # b.directories.count.should eq(3)
  # end
#   
  # it "should list files" do
    # b = S3bucket.new(:name => TEST_BUCKET)
    # b.ls('bogus').should eq(nil)
    # b.ls('FreeTEST').count.should eq(1)
    # b.ls('FreeTEST/Dir1').count.should eq(2)
  # end
#   
  # it "should flush to tmp" do
    # b = S3bucket.new(:name => TEST_BUCKET)
    # ['FreeTEST/Dir1', 'FreeTEST/Dir2'].each do |dir|
      # b.flush_to_slash_tmp(dir)
#       
      # b.ls(dir).count.should eq(2)
      # Dir.entries(File.join(S3bucket::TMP_DIR_PREFIX, b.name, dir)).count.should eq(4)
#       
    # end
  # end
# end
# 
# 
# def setup
  # c = Fog::Storage.new(:provider => 'AWS')
  # bucket = c.directories.get(TEST_BUCKET)
  # bucket.files.create(:key => 'FreeTEST/File0.txt', :body => "test", :public => true)
  # bucket.files.create(:key => 'FreeTEST/Dir1/File1.txt', :body => "test", :public => true)
  # bucket.files.create(:key => 'FreeTEST/Dir1/File2.txt', :body => "test", :public => true)
  # bucket.files.create(:key => 'FreeTEST/Dir2/File3.txt', :body => "test", :public => true)
  # bucket.files.create(:key => 'FreeTEST/Dir2/File4.txt', :body => "test", :public => true)
#   
# end