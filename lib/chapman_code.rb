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
module ChapmanCode

  ###################
  #Note the actual list of codes is the merge_counties or select_hash
  #######################

  def self.name_from_code(code)
    codes = merge_countries
    codes.invert[code]
  end

  def self.remove_codes(hash)
    hash = ChapmanCode::CODES.each_pair do |key, value|
      FreeregOptionsConstants::CHAPMAN_CODE_ELIMINATIONS.each do |country|
        value.delete_if {|key, value| key == country }
      end
    end
    hash
  end

  def self.add_parenthetical_codes(hash)
    hsh = {}
    hash.each_pair do |key, value|
      hsh[key] = Hash[value.map { |k,v| ["#{k} (#{v})", v] }]
    end
    hsh
  end

  def self.values
    codes = merge_countries
    code = codes.values
  end

  def self.has_key?(code)
    codes = merge_countries
    codes.has_key?(code)
  end

  def self.values_at(value)
    codes = merge_countries
    array = codes.values_at(value)
    array[0]
  end

  def self.select_hash
    codes = merge_countries
    codes
  end

  def self.keys
    codes = merge_countries
    mine = Array.new
    codes.each_key do |k|
      mine << k
    end
    mine
  end

  def self.select_hash_with_parenthetical_codes
    hash = ChapmanCode::CODES.each_pair do |key, value|
      ChapmanCode::CODES[key] = Hash[value.map { |k,v| ["#{k} (#{v})", v] }]
    end
    hash
  end

  def self.has_key(value)
    codes = merge_countries
    codes.key(value)
  end

  def self.value?(value)
    codes = merge_countries
    codes.value?(value)
  end

  CODES = {
    "England" =>
    {'England' => 'ENG',
     'Bedfordshire' => 'BDF',
     'Berkshire' => 'BRK',
     'Buckinghamshire' => 'BKM',
     'Cambridgeshire' => 'CAM',
     'Cheshire' => 'CHS',
     'Cornwall' => 'CON',
     'Cumberland' => 'CUL',
     'Derbyshire' => 'DBY',
     'Devon' => 'DEV',
     'Dorset' => 'DOR',
     'Durham' => 'DUR',
     'Essex' => 'ESS',
     'Gloucestershire' => 'GLS',
     'Hampshire' => 'HAM',
     'Herefordshire' => 'HEF',
     'Hertfordshire' => 'HRT',
     'Huntingdonshire' => 'HUN',
     'Isle of Wight' => 'IOW',
     'Kent' => 'KEN',
     'Lancashire' => 'LAN',
     'Leicestershire' => 'LEI',
     'Lincolnshire' => 'LIN',
     'London (City)' => 'LND',
     'Middlesex' => 'MDX',
     'Norfolk' => 'NFK',
     'Northamptonshire' => 'NTH',
     'Northumberland' => 'NBL',
     'Nottinghamshire' => 'NTT',
     'Oxfordshire' => 'OXF',
     'Rutland' => 'RUT',
     'Shropshire' => 'SAL',
     'Somerset' => 'SOM',
     'Staffordshire' => 'STS',
     'Suffolk' => 'SFK',
     'Surrey' => 'SRY',
     'Sussex' => 'SSX',
     'Warwickshire' => 'WAR',
     'Westmorland' => 'WES',
     'Wiltshire' => 'WIL',
     'Worcestershire' => 'WOR',
     'Yorkshire' => 'YKS',
     'Yorkshire, East Riding' => 'ERY',
     'Yorkshire, North Riding' => 'NRY',
     'Yorkshire, West Riding' => 'WRY'},
    "Islands" =>{
      'Channel Islands' => 'CHI',
      'Alderney' => 'ALD',
      'Guernsey' => 'GSY',
      'Jersey' => 'JSY',
      'Isle of Man' => 'IOM',
      'Sark' => 'SRK'

    },
    "Scotland" =>
    {'Scotland' => 'SCT',
     'Aberdeenshire' => 'ABD',
     'Angus (Forfarshire)' => 'ANS',
     'Argyllshire' => 'ARL',
     'Ayrshire' => 'AYR',
     'Banffshire' => 'BAN',
     'Berwickshire' => 'BEW',
     'Borders' => 'BOR',
     'Bute' => 'BUT',
     'Caithness' => 'CAI',
     'Central' => 'CEN',
     'Clackmannanshire' => 'CLK',
     'Dumfries and Galloway' => 'DGY',
     'Dumfriesshire' => 'DFS',
     'Dunbartonshire' => 'DNB',
     'East Lothian' => 'ELN',
     'Fife' => 'FIF',
     'Grampian' => 'GMP',
     'Highland' => 'HLD',
     'Inverness-shire' => 'INV',
     'Kincardineshire' => 'KCD',
     'Kinross-shire' => 'KRS',
     'Kirkcudbrightshire' => 'KKD',
     'Lanarkshire' => 'LKS',
     'Lothian' => 'LTN',
     'Midlothian' => 'MLN',
     'Morayshire' => 'MOR',
     'Nairnshire' => 'NAI',
     'Orkney' => 'OKI',
     'Orkney Isles' => 'OKI',
     'Peeblesshire' => 'PEE',
     'Perthshire' => 'PER',
     'Renfrewshire' => 'RFW',
     'Ross and Cromarty' => 'ROC',
     'Roxburghshire' => 'ROX',
     'Selkirkshire' => 'SEL',
     'Shetland' => 'SHI',
     'Shetland Isles' => 'SHI',
     'Stirlingshire' => 'STI',
     'Strathclyde' => 'STD',
     'Sutherland' => 'SUT',
     'Tayside' => 'TAY',
     'West Lothian' => 'WLN',
     'Western Isles' => 'WIS',
     'Wigtownshire' => 'WIG'},
    "Wales" =>
    {'Wales' => 'WLS',
     'Anglesey' => 'AGY',
     'Brecknockshire' => 'BRE',
     'Caernarfonshire' => 'CAE',
     'Cardiganshire' => 'CGN',
     'Carmarthenshire' => 'CMN',
     'Clwyd' => 'CWD',
     'Denbighshire' => 'DEN',
     'Dyfed' => 'DFD',
     'Flintshire' => 'FLN',
     'Glamorgan' => 'GLA',
     'Mid Glamorgan' => 'MGM',
     'South Glamorgan' => 'SGM',
     'West Glamorgan' => 'WGM',
     'Gwent' => 'GNT',
     'Gwynedd' => 'GWN',
     'Merionethshire' => 'MER',
     'Monmouthshire' => 'MON',
     'Montgomeryshire' => 'MGY',
     'Pembrokeshire' => 'PEM',
     'Powys' => 'POW',
     'Radnorshire' => 'RAD'},
     "Northern Ireland" =>
     {"Northern Ireland" => 'NIR',
     'Antrim' => 'ANT',
     'Armagh' => 'ARM',
     'Down' => 'DOW',
     'Fermanagh' => 'FER',
     'Londonderry' => 'LDY',
     'Tyrone' => 'TYR'},
     'Unknown' => 
     {'Unknown' => 'UNK'}
  }


  def self.merge_countries
    all_countries = {}
    ChapmanCode::CODES.each_pair do |key,value|
      all_countries.merge!(CODES[key])
    end
    all_countries
  end

  #Note the actual list of codes is the merge_counties or select_hash
  def self.merge_counties
    all_counties = Array.new
    all_counties = County.distinct(:chapman_code)
    all_counties
  end
end
