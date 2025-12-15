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
#require 'rspec/autorun'

require 'record_type'

require 'new_freereg_csv_update_processor'

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
  config.color = true

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

def clean_freereg1_csv_file_document(file)
  Freereg1CsvFile.file_name(file[:file]).userid(file[:user]).delete
end
def clean_database
  PhysicalFile.delete_all
  AtticFile.delete_all
  SearchRecord.delete_all
  Freereg1CsvEntry.delete_all
  Freereg1CsvFile.delete_all
  Register.delete_all
  Church.delete_all
  Place.delete_all
end


def create_stub_church(file)
  place = Place.where(:place_name => file[:placename], :chapman_code => file[:chapman_code]).first
  church = Church.where(:place_id => place.id,:church_name => file[:churchname]).first
  if !church
    church = Church.create!(:church_name => file[:churchname])
    place.churches << church
    place.save!
  end
  church
end

def create_stub_place(file)
  # create stub place
  place = Place.where(:place_name => file[:placename], :chapman_code => file[:chapman_code]).first
  place.approve if place.present?
  unless place
    place = Place.create!(:place_name => file[:placename], :chapman_code => file[:chapman_code], :latitude => 60, :longitude => 0, :modified_place_name => file[:placename].gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase)
    place.approve
    place.save!
  end
  place
end

def create_stub_userid(file)
  # create_stub user
  username = file[:user]
  userid = UseridDetail.userid(username).first
  unless userid
    u = Refinery::Authentication::Devise::User.where(:username => username).first
    u.delete unless u.nil?
    userid = UseridDetail.create!(:userid=>username, :password=>username, :email_address=>"#{username}@example.com", :person_surname => username, :person_forename => username, :syndicate => 'test')
  end
  userid
end

def create_new_user(username)
  userid = UseridDetail.userid(username).first
  unless userid
    u = Refinery::Authentication::Devise::User.where(:username => username).first
    u.delete unless u.nil?
    userid = UseridDetail.create!(:userid=>username, :password=>username, :email_address=>"#{username}@example.com", :person_surname => username, :person_forename => username, :syndicate => 'test')
  end
  folder_location = create_stub_userid_folder(username)
  return userid,folder_location
end

def create_stub_userid_folder(username)
  folder_location = File.join(Rails.application.config.datafiles,username)
  Dir.mkdir(folder_location,0774) unless Dir.exist?(folder_location)
  folder_location
end

def get_line
  processing_file = Rails.application.config.delete_list
  line = File.open(processing_file, &:readline)
end


def process_test_file(file)
  userid = create_stub_userid(file)
  place = create_stub_place(file)
  church = create_stub_church(file)
  Rails.application.config.datafiles = file[:basedir]
  NewFreeregCsvUpdateProcessor.activate_project('create_search_records','individual','force_rebuild',file[:filename])
  freereg1_csv_file = Freereg1CsvFile.userid(file[:user]).file_name(file[:file]).first
end


def setup_userids
  Dir.glob(File.join(Rails.root, 'test_data', 'freereg1_csvs', '*')).
    map{|fn| File.basename(fn)}.
    each{|uid| UseridDetail.create!(:userid => uid, :password => uid, :encrypted_password => uid, :email_address => "#{uid}@example.com", :person_surname => uid, :person_forename => uid, :syndicate => 'test') unless UseridDetail.where(:userid => uid).first}
end

def set_up_new_location(file)
  register = file.register
  church = register.church
  place = church.place
  sess = {}
  par ={}
  sess[:selectcountry] = file.country
  sess[:selectcounty] = file.county
  sess[:selectplace] = place.id
  sess[:selectchurch] = church.id
  par[:register_type] = file.register_type
  return par,sess
end

def write_new_copy(user,file_name)
  #this is used to replace the removed file
  userid = UseridDetail.userid(user).first
  file = AtticFile.userid(userid.id).first
  folder = create_stub_userid_folder(user)
  new_file = File.join(folder,file_name)
  old_file = File.join(Rails.application.config.datafiles,user,".attic",file.name)
  File.rename(old_file,new_file)
end

FREEREG1_CSV_FILES = [
  {
    :filename => "kirknorfolk/NFKALEBU.csv",
    :file => "NFKALEBU.csv",
    :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
    :type => RecordType::BURIAL,
    :user => 'kirknorfolk',
    :chapman_code => 'NFK',
    :placename => 'Aldeby',
    :churchname => 'St Mary',
    :register_type => "BT",
    :minimum_date => "1690",
    :maximum_date => "1698",
    :entry_count => 15,
    :entries => {
      :first => {
        :line_id => "kirknorfolk.NFKALEBU.CSV.1",
        :burial_person_forename => 'Will',
        :burial_person_surname => 'SADD',
        :burial_date => '6 Mar 1690/1',
        :modern_year => 1691
      },
      :last => {
        :line_id => "kirknorfolk.NFKALEBU.CSV.15",
        :burial_person_forename => 'Robert',
        :burial_person_surname => 'LONDON',
        :burial_date => '7 Nov 1691',
        :modern_year => 1691
      }
    }
  },
  {
    :filename => "kirkbedfordshire/BDFYIEBA.CSV",
    :file => "BDFYIEBA.CSV",
    :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
    :type => RecordType::BAPTISM,
    :user => 'kirkbedfordshire',
    :chapman_code => 'BDF',
    :placename => 'Yielden',
    :churchname => 'St Fictional',
    :entry_count => 1223,
    :register_type => "PR",
    :minimum_date => "1602",
    :maximum_date => "1812",
    :entries => {
      :first => {
        :line_id => "kirkbedfordshire.BDFYIEBA.CSV.1",
        :baptism_date => '30 Aug 1602',
        :person_forename => 'Paul',
        :person_sex => 'M',
        :father_forename  => 'Thomas',
        :father_surname => 'MAXEE',
        :modern_year => 1602
      },
      :last => {
        :line_id => "kirkbedfordshire.BDFYIEBA.CSV.1223",
        :baptism_date => '19 Oct 1812',
        :person_forename => 'Elizabeth',
        :mother_forename => 'Susan',
        :person_sex => 'F',
        :father_surname  => 'CHARLES',
        :father_forename => 'Joseph',
        :modern_year => 1812
      }
    }
  },
  {
    # :filename => "/home/benwbrum/dev/clients/freeukgen/scratch/Chd/HRTCALMA.csv",
    # :basedir => "/home/benwbrum/dev/clients/freeukgen/scratch/",
    :filename => "Chd/HRTCALMA.csv",
    :file => "HRTCALMA.csv",
    :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
    :type => RecordType::MARRIAGE,
    :user => 'Chd',
    :chapman_code => 'HRT',
    :placename => 'Caldecote',
    :churchname => 'St Mary Magdalene',
    :entry_count => 45,
    :register_type => "AT",
    :minimum_date => "1726",
    :maximum_date => "1837",
    :entries => {
      :first => {
        :line_id => "Chd.HRTCALMA.CSV.1",
        :marriage_date => '4 Oct 1726',
        :bride_surname => 'CANNON',
        :bride_forename => 'Sarah',
        :groom_surname => 'SAUNDERS',
        :groom_forename => 'William',
        :modern_year => 1726
      },
      :last => {
        :line_id => "Chd.HRTCALMA.CSV.45",
        :marriage_date => '12 Oct 1837',
        :bride_surname => 'GARRATT',
        :bride_forename => 'Anne',
        :groom_surname => 'CLARKE',
        :groom_forename => 'Charles',
        :modern_year => 1837,
        :witnesses => [
          { :first_name => 'William', :last_name => 'CLARKE'},
          { :first_name => 'Mary', :last_name => 'GARRATT'}
        ]
      }
    }
  },
  {
    :filename => "Devonian/DEVLANBU.CSV",
    :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
    :file => "DEVLANBU.CSV",
    :type => RecordType::BURIAL,
    :user => 'Devonian',
    :chapman_code => 'DEV',
    :placename => 'Landcross',
    :churchname => 'Holy Trinity',
    :entry_count => 128,
    :register_type => "PR",
    :minimum_date => "1594",
    :maximum_date => "1811",
    :entries => {
      :first => {
        :line_id => "Devonian.DEVLANBU.CSV.1",
        :burial_person_forename => 'John',
        :relative_surname => 'NORTHWAY',
        :burial_date => '7 Dec 1802',
        :modern_year => 1802
      }, # add problem entry here
      :last => {
        :line_id => "Devonian.DEVLANBU.CSV.128",
        :burial_person_forename => 'Richardus',
        :burial_person_surname => 'OXENHAM',
        :burial_date => '13 Mar 1693/4',
        :modern_year => 1694
      }
    }
  },
  {
    :filename => "Chd/HRTWILMA.csv",
    :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
    :file => "HRTWILMA.csv",
    :type => RecordType::MARRIAGE,
    :user => 'Chd',
    :chapman_code => 'HRT',
    :placename => 'Willian',
    :churchname => 'All Saints',
    :entry_count => 545,
    :register_type => "EX",
    :minimum_date => "1559",
    :maximum_date => "1911",
    :entries => {
      :first => {
        :line_id => "Chd.HRTWILMA.csv.1",
        :marriage_date => '8 Oct 1559',
        :bride_surname => 'CHATTERTON',
        :bride_forename => 'Margerie',
        :groom_surname => 'BUCKMASTER',
        :groom_forename => 'Thomas',
        :modern_year => 1559
      },
      :last => {
        :line_id => "Chd.HRTWILMA.csv.545",
        :marriage_date => '11 Nov 1911',
        :bride_surname => 'SWAIN',
        :bride_forename => 'Bessie Malinda',
        :groom_surname => 'BROWN',
        :groom_forename => 'Percy',
        :bride_father_surname => 'SWAIN',
        :bride_father_forename => 'Thomas',
        :groom_father_surname => 'BROWN',
        :groom_father_forename => 'Charles',
        :modern_year => 1911
      }
    }
}]


ARTIFICIAL_FILES = [
  {
    :filename => "artificial/double_latinization.csv",
    :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
    :file => "double_latinization.csv",
    :chapman_code => 'NTH',
    :placename => 'Gretton',
    :churchname => 'St James',
    :entry_count => 1,
    :register_type => "PR",
    :minimum_date => "1798",
    :maximum_date => "1798",
    :user => 'artificial'
  },
  {
    :filename => "artificial/multiple_expansions.csv",
    :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
    :file => "multiple_expansions.csv",
    :chapman_code => 'LEI',
    :placename => 'Belton',
    :churchname => 'St John The Baptist',
    :entry_count => 1,
    :register_type => "DW",
    :minimum_date => "1739",
    :maximum_date => "1739",
    :user => 'artificial'
  }
]

EMENDATION_FILES = [
  {
    :filename => "artificial/double_latinization.csv",
    :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
    :file => "double_latinization.csv",
    :entry_count => 1,
    :register_type => "PR",
    :minimum_date => "1798",
    :maximum_date => "1798",
    :user => 'artificial'
  },
  {
    :filename => "artificial/multiple_expansions.csv",
    :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
    :file => "multiple_expansions.csv",
    :entry_count => 1,
    :register_type => "DW",
    :minimum_date => "1739",
    :maximum_date => "1739",
    :user => 'artificial'
  }
]

NO_BAPTISMAL_NAME =
{
  :filename => "BobChown/KENSTIBA1.csv",
  :basedir => "#{Rails.root}/test_data/freereg1_csvs/artificial/",
  :file => "KENSTIBA1.csv",
  :chapman_code => 'KEN',
  :placename => 'Stone in Oxney',
  :churchname => 'St Mary',
  :entry_count => 1,
  :register_type => "TR",
  :minimum_date => "1553",
  :maximum_date => "1553",
  :user => 'BobChown'
}

NO_BURIAL_FORENAME =
{
  :filename => "1boy7girls/LINBEEBU.CSV",
  :basedir => "#{Rails.root}/test_data/freereg1_csvs/artificial/",
  :file => "LINBEEBU.CSV",
  :chapman_code => 'LIN',
  :placename => 'Beelsby',
  :churchname => 'St Andrew',
  :entry_count => 2,
  :register_type => "PR",
  :minimum_date => "1935",
  :maximum_date => "1935",
  :user => '1boy7girls'
}

NO_RELATIVE_SURNAME =
{
  :filename => "brilyn/NFKWYMBU.CSV",
  :basedir => "#{Rails.root}/test_data/freereg1_csvs/artificial/",
  :file => "NFKWYMBU.CSV",
  :chapman_code => 'NFK',
  :placename => 'Wymondham',
  :churchname => "Virgin Mary And St Thomas A Becket",
  :entry_count => 1,
  :register_type => "AT",
  :minimum_date => "1781",
  :maximum_date => "1781",
  :user => 'brilyn'
}


SQUARE_BRACE_UCF =
{
  :filename => "artificial/ucf_nostar.csv",
  :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
  :file => "ucf_nostar.csv",
  :chapman_code => 'NTH',
  :placename => 'Gretton',
  :churchname => "St James",
  :entry_count => 17,
  :register_type => "",
  :minimum_date => "1798",
  :maximum_date => "1798",
  :user => 'artificial'
}

WILDCARD_UCF =
{
  :filename => "artificial/ucf_star.csv",
  :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
  :file => "ucf_star.csv",
  :chapman_code => 'SOM',
  :placename => 'Runnington',
  :churchname => 'St Peter',
  :entry_count => 8,
  :register_type => "",
  :minimum_date => "1734",
  :maximum_date => "1798",
  :user => 'artificial'
}

BAPTISM_BIRTH =
{
  :filename => "artificial/birth_date_ba.csv",
  :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
  :file => "birth_date_ba.csv",
  :chapman_code => 'KEN',
  :placename => 'Stone in Oxney',
  :churchname => 'St Mary',
  :entry_count => 1,
  :register_type => "TR",
  :minimum_date => "1553",
  :maximum_date => "1653",
  :user => 'artificial'
}

WILDCARD_DATES =
{
  :filename => "artificial/unclear_date_ba.csv",
  :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
  :file => "unclear_date_ba.csv",
  :chapman_code => 'KEN',
  :placename => 'Stone in Oxney',
  :churchname => 'St Mary',
  :entry_count => 1,
  :register_type => "TR",
  :minimum_date => "1653",
  :maximum_date => "1653",
  :user => 'artificial'
}
CHANGELESS_FILE =
{
  :filename => "jelit/SSXSESBU.CSV",
  :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
  :file => "SSXSESBU.CSV",
  :chapman_code => 'SSX',
  :placename => 'Selsey',
  :churchname => 'St Peter',
  :entry_count => 835,
  :register_type => "PR",
  :minimum_date => "1813",
  :maximum_date => "1866",
  :user => 'jelit'
}




DELTA_FILES = [
  {
    :filename => "artificial/deltas/v1/kirknorfolk/NFKALEBU.csv",
    :basedir => "#{Rails.root}/test_data/freereg1_csvs/artificial/deltas/v1/",
    :file => "NFKALEBU.csv",
    :chapman_code => 'NFK',
    :placename => 'Aldeby',
    :churchname => 'St Mary',
    :entry_count => 15,
    :register_type => "BT",
    :minimum_date => "1690",
    :maximum_date => "1691",
    :user => 'kirknorfolk'
  },
  {
    :filename => "artificial/deltas/v2/kirknorfolk/NFKALEBU.csv",
    :basedir => "#{Rails.root}/test_data/freereg1_csvs/artificial/deltas/v2/",
    :file => "NFKALEBU.csv",
    :chapman_code => 'NFK',
    :placename => 'Aldeby',
    :churchname => 'St Mary',
    :entry_count => 15,
    :register_type => "BT",
    :minimum_date => "1690",
    :maximum_date => "1691",
    :user => 'kirknorfolk'
  },
  {
    :filename => "artificial/deltas/v3/kirknorfolk/NFKALEBU.csv",
    :basedir => "#{Rails.root}/test_data/freereg1_csvs/artificial/deltas/v3/",
    :file => "NFKALEBU.csv",
    :chapman_code => 'NFK',
    :placename => 'Aldeby',
    :churchname => 'St Mary',
    :entry_count => 15,
    :register_type => "BT",
    :minimum_date => "1690",
    :maximum_date => "1691",
    :user => 'kirknorfolk'
  }
]


EMBARGO_FILES = [
  {
    :filename => "artificial/embargoed_baptism.csv",
    :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
    :file => "embargoed_baptism.csv",
    :chapman_code => 'NFK',
    :placename => 'Norwich',
    :churchname => 'Octagon Unitarian Chapel',
    :entry_count => 2,
    :register_type => "",
    :minimum_date => "1691",
    :maximum_date => "1941",
    :user => 'artificial'
  },
  {
    :filename => "artificial/embargoed_marriage.csv",
    :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
    :file => "embargoed_marriage.csv",
    :chapman_code => 'LIN',
    :placename => 'Great Hale',
    :churchname => 'St John',
    :entry_count => 2,
    :register_type => "",
    :minimum_date => "1915",
    :maximum_date => "1949",
    :user => 'artificial'
  },
  {
    :filename => "artificial/embargoed_burial.csv",
    :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
    :file => "embargoed_burial.csv",
    :chapman_code => 'NFK',
    :placename => 'Ingham',
    :churchname => 'St John',
    :entry_count => 2,
    :register_type => "AT",
    :minimum_date => "1726",
    :maximum_date => "2014",
    :user => 'artificial'
  }
]
