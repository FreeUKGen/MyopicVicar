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
require 'record_type'
class Freereg1CsvFile 
  include MongoMapper::Document
  many :freereg1_csv_entries
  belongs_to :register
#  belongs_to :place




  # Fields correspond to cells in CSV headers  
  key :county, String 
  key :place, String 
  key :church_name, String 
  key :register_type, String
  key :record_type, String, :in => RecordType::ALL_TYPES+[nil]

  key :records, String
  key :datemin, String
  key :datemax, String
  key :daterange, Array
  key :userid, String
  key :file_name, String
  key :transcriber_name, String
  key :transcriber_email, String
  key :transcriber_syndicate, String
  key :credit_email, String
  key :credit_name, String
  key :first_comment, String
  key :second_comment, String
  key :transcription_date, String
  key :modification_date, String
  key :lds, String
  key :characterset, String
  timestamps!


  def ordered_display_fields
    order = []
    order << 'county'
    order << 'place'
    order << 'register'
    order << 'register_type'
    order << 'record_type'
    order << 'file_name'
    order << 'transcriber_name'
    order << 'transcriber_syndicate'
    order << 'credit_name'
    order << 'first_comment'
    order << 'second_comment'

    order
  end
  
  def update_register
    Register.update_or_create_register(self)
  end

  def to_register
    { :chapman_code => county,
      :register_type => register_type,
      :place_name => place,
      :church_name => church_name,
      :start_year => datemin,
      :end_year => datemax,
      :record_types => [record_type],
      :transcribers => [credit_name]
      }
  end


end
