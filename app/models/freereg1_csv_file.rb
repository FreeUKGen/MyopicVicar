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
  include Mongoid::Document
  include Mongoid::Timestamps
  has_many :freereg1_csv_entries
  belongs_to :register
  #belongs_to :place




  # Fields correspond to cells in CSV headers  
  field :county, type: String 
  field :place, type: String 
  field :church_name, type: String 
  field :register_type, type: String
  field :record_type, type: String#, :in => RecordType::ALL_TYPES+[nil]
  validates_inclusion_of :record_type, :in => RecordType::ALL_TYPES+[nil]
  field :records, type: String
  field :datemin, type: String
  field :datemax, type: String
  field :daterange, type: Array
  field :userid, type: String
  field :file_name, type: String
  field :transcriber_name, type: String
  field :transcriber_email, type: String
  field :transcriber_syndicate, type: String
  field :credit_email, type: String
  field :credit_name, type: String
  field :first_comment, type: String
  field :second_comment, type: String
  field :transcription_date, type: String
  field :modification_date, type: String
  field :lds, type: String
  field :characterset, type: String

  index({file_name:1,userid:1,county:1,place:1,church_name:1,register_type:1})
  index({register_id:1})
  index({ounty:1,place:1,church_name:1,register_type:1, record_type: 1})

  def ordered_display_fields
    order = []
 #   order << 'county'
 #   order << 'place'
    order << 'register'
    order << 'register_type'
    order << 'record_type'
    order << 'file_name'
#    order << 'transcriber_name'
    order << 'transcriber_syndicate'
#    order << 'credit_name'
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
      :number_of_records => records,
      :decade_population => daterange,
      :start_year => datemin,
      :end_year => datemax,
      :file_name => file_name,
      :user_id => userid,
      :record_types => [record_type],
      :transcribers => transcriber_name
      }
  end


end
