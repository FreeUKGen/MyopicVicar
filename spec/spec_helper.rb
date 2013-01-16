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
# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false
end


FREEREG1_CSV_FILES = [
  { 
    :filename => "#{Rails.root}/test_data/freereg1_csvs/kirknorfolk/NFKHSPBU.csv",
    :type => Freereg1CsvFile::RECORD_TYPES::BURIAL,
    :user => 'kirknorfolk',
    :chapman_code => 'NFK',
    :entry_count => 221,
    :entries => {
      :first => {
        :baptism_date => '1700'
      },
      :last => {
        :baptism_date => '1812'
      }
    }
   },
  { 
    :filename => "#{Rails.root}/test_data/freereg1_csvs/kirkbedfordshire/BDFYIEBA.CSV",
    :type => Freereg1CsvFile::RECORD_TYPES::BAPTISM,
    :user => 'kirkbedfordshire',
    :chapman_code => 'BDF',
    :entry_count => 1223,
    :entries => {
      :first => {
        :baptism_date => Date.parse('1602-08-30')
      },
      :last => {
        :baptism_date => Date.parse('1812-10-19')
      }
    }
   },
  { 
    :filename => "#{Rails.root}/test_data/freereg1_csvs/Chd/HRTCALMA.csv",
    :type => Freereg1CsvFile::RECORD_TYPES::MARRIAGE,
    :user => 'Chd',
    :chapman_code => 'HRT',
    :entry_count => 45,
    :entries => {
      :first => {
        :baptism_date => Date.parse('1726-10-04')
      },
      :last => {
        :baptism_date => Date.parse('1837-10-12')
      }
    }
   }
]
