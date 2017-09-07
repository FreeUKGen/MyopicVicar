# Copyright 2012 Trustees of FreeBMD
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 
require 'spec_helper'

describe ImageFile do
  # SIMPLE_DIR = "#{Rails.root}/test_data/mvuploads/simpletest"
  # ZIP_FILENAME = "#{Rails.root}/test_data/mvuploads/heterogenoustest/Flintshire 1861.zip" 
  # IMAGE_FILENAME = "#{Rails.root}/test_data/mvuploads/heterogenoustest/4143523_01206.jpg"
  # PDF_FILENAME = "#{Rails.root}/test_data/mvuploads/heterogenoustest/SSCens Tutorial_Spread_1p.pdf"
  # THUMB_FILENAME = "#{Rails.root}/test_data/mvuploads/heterogenoustest/4143523_01206_thumb.png"
# 
  # it "should deal correctly with working copies" do
    # iu=Upload.new
    # iu.upload_path=SIMPLE_DIR
    # iu.process_upload
    # f = iu.image_dir.first.image_file.first
#     
    # # check that new files are considered original
    # f.original?.should eq(true)
    # f.original_name.should eq(nil)
    # f.name.should_not eq(f.original_name)
    # old_name = f.name
    # # do something
    # f.deskew
#       
    # # check that files are not original
    # f.original?.should_not eq(true)
    # f.original_name.should_not eq(nil)
    # f.original_name.should eq(old_name)
#     
    # # new derived file should exist
    # new_name = f.name
    # File.exists?(new_name).should eq(true)
#     
    # # revert
    # f.revert
#     
    # # check that files are original again
    # f.original?.should eq(true)
    # f.original_name.should eq(nil)
    # f.name.should_not eq(f.original_name)
    # File.exists?(new_name).should eq(false)
#     
  # end
#   
  # it "should update thumbnails and metadata after changes" do
    # iu=Upload.new
    # iu.upload_path=SIMPLE_DIR
    # iu.process_upload
    # f = iu.image_dir.first.image_file.first
#     
    # # check coordinates in the DB
    # orig_x=f.width
    # orig_y=f.height
    # # check filesystem for thumbnail
    # orig_size=File.size(f.name)
    # orig_thumb_size=File.size(f.thumbnail_name)
# 
    # # do something
    # f.rotate(90)
#       
    # # recheck filesystem
    # File.size(f.name).should_not eq(orig_size)
    # File.size(f.thumbnail_name).should_not eq(orig_size)
    # # recheck coordinates
    # f.width.should_not eq(orig_x)
    # f.height.should_not eq(orig_y)
#     
  # end
# 
  # it "should transpose measurements after a rotate" do
    # iu=Upload.new
    # iu.upload_path=SIMPLE_DIR
    # iu.process_upload
    # f = iu.image_dir.first.image_file.first
#     
    # # check coordinates in the DB
    # orig_x=f.width
    # orig_y=f.height
# 
    # # do something
    # f.rotate(90)
#       
    # # recheck coordinates
    # f.width.should eq(orig_y)
    # f.height.should eq(orig_x)
#     
    # nf = ImageFile.find(f.id)
    # nf.width.should eq f.width
    # nf.height.should eq f.height
    # nf.name.should eq f.name
#     
  # end
# 
  # it "should test for zipfiles" do
    # ImageFile.is_image?(ZIP_FILENAME).should eq false
  # end
  # it "should test for pdf files" do
    # ImageFile.is_image?(PDF_FILENAME).should eq false
#     
  # end
  # it "should test for images files" do
    # ImageFile.is_image?(IMAGE_FILENAME).should eq true
  # end
#  
#  
  # it "should create a thumbnail" do
    # i = ImageFile.create(:name => test_file)
    # File.exists?(i.thumbnail_name).should be_true
  # end
#   
  # it "should read height and width" do
    # i = ImageFile.create(:name => test_file)
    # i.height.should eq 3162
    # i.width.should eq 4038
  # end
# 
# 
  # BASE_DIR = "/tmp/image_file_spec"
# 
  # def test_file
    # # quarantine the files
    # unless @dir
      # Dir.mkdir(BASE_DIR) unless File.exists?(BASE_DIR)
      # @dir=File.join(BASE_DIR, Time.now.strftime("%s"))
# 
      # FileUtils.rm_rf(@dir)
      # Dir.mkdir(@dir)
      # FileUtils.cp(IMAGE_FILENAME, @dir)
    # end
    # File.join(@dir, File.basename(IMAGE_FILENAME))
  # end
  
end
