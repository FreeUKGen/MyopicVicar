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
class ImageUploadLog
  include Mongoid::Document
  include Mongoid::Timestamps

  require 'date'

# Validations :::::::::::::::::::::::::::::::::::::::::::::::::::::
# validates_presence_of :attribute

# Assocations :::::::::::::::::::::::::::::::::::::::::::::::::::::
# belongs_to :model
# many :model
# one :model
  belongs_to :upload


# Callbacks ::::::::::::::::::::::::::::::::::::::::::::::::::::::: 
# before_create :your_model_method
# after_create :your_model_method
# before_update :your_model_method 
  after_create :initialize_logfile

# Attribute options extras ::::::::::::::::::::::::::::::::::::::::
# attr_accessible :first_name, :last_name, :email

# Validations
# key :name, :required =>  true      

# Defaults
# key :done, :default => false

# Typecast
# key :user_ids, Array, :typecast => 'ObjectId'
  
   
  field :file, type: String

  def initialize_logfile
    dirname = File.join("log/upload", Date.today.to_s)
    FileUtils.mkdir(dirname) unless File.directory?(dirname)
    self.file = File.join(dirname, "upload_#{self.id}.log")
    @logger = Logger.new(self.file)
    @logger.level = Logger::INFO
    self.save!
  end

  def log(msg)
    initialize_logfile unless @logger
    @logger.info(msg)
  end

  def read
    File.read(self.file)
  end

end
