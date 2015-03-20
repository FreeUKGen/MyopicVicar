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

  def self.name_from_code(code)
    CODES.invert[code]
  end
  
  def self.remove_codes(hash)
   FreeregOptionsConstants::CHAPMAN_CODE_ELIMINATIONS.each do |country|
     hash.delete_if {|key, value| key == country }
   end 
  hash 
  end

  def self.add_parenthetical_codes(hash)
    Hash[hash.map { |k,v| ["#{k} (#{v})", v] }]
  end
   
  def self.values
    CODES::values
  end 

  def self.has_key?(code)
    CODES.has_key?(code)
  end

  def self.values_at(value)
    array = CODES.values_at(value)
    array[0]
  end
  
  def self.select_hash
    CODES
  end

  def self.keys
  mine = Array.new
  CODES.each_key do |k| 
    mine << k
   end   
   mine
  end

  def self.select_hash_with_parenthetical_codes
    Hash[ChapmanCode::CODES.map { |k,v| ["#{k} (#{v})", v] }]
  end

  def self.has_key(value)
    CODES.key(value)
  end

  def self.value?(value)
    CODES.value?(value)  
  end

  CODES = {
    'Aberdeenshire' => 'ABD',
    'Alderney' => 'ALD',
    'Anglesey' => 'AGY',
    'Angus (Forfarshire)' => 'ANS',
    'Argyllshire' => 'ARL',
    'Ayrshire' => 'AYR',
    'Banffshire' => 'BAN',
    'Bedfordshire' => 'BDF',
    'Berkshire' => 'BRK',
    'Berwickshire' => 'BEW',
    'Brecknockshire' => 'BRE',
    'Buckinghamshire' => 'BKM',
    'Bute' => 'BUT',
    'Caernarfonshire' => 'CAE',
    'Caithness' => 'CAI',
    'Cambridgeshire' => 'CAM',
    'Cardiganshire' => 'CGN',
    'Carmarthenshire' => 'CMN',
    'Channel Islands' => 'CHI',
    'Cheshire' => 'CHS',
    'Clackmannanshire' => 'CLK',
    'Cornwall' => 'CON',
    'Cumberland' => 'CUL',
    'Denbighshire' => 'DEN',
    'Derbyshire' => 'DBY',
    'Devon' => 'DEV',
    'Dorset' => 'DOR',
    'Dumfriesshire' => 'DFS',
    'Dunbartonshire' => 'DNB',
    'Durham' => 'DUR',
    'East Lothian' => 'ELN',
    'Essex' => 'ESS',
    'Fife' => 'FIF', 
    'Flintshire' => 'FLN',
    'Glamorgan' => 'GLA',
    'Gloucestershire' => 'GLS',
    'Guernsey' => 'GSY',
    'Hampshire' => 'HAM',
    'Herefordshire' => 'HEF',
    'Hertfordshire' => 'HRT',
    'Huntingdonshire' => 'HUN',
    'Inverness-shire' => 'INV',
    'Isle of Man' => 'IOM',
    'Isle of Wight' => 'IOW',
    'Jersey' => 'JSY',
    'Kent' => 'KEN',
    'Kincardineshire' => 'KCD',
    'Kinross-shire' => 'KRS',
    'Kirkcudbrightshire' => 'KKD',
    'Lanarkshire' => 'LKS',
    'Lancashire' => 'LAN',
    'Leicestershire' => 'LEI',
    'Lincolnshire' => 'LIN',
    'London (City)' => 'LND',
    'Merionethshire' => 'MER',
    'Middlesex' => 'MDX',
    'Midlothian' => 'MLN',
    'Monmouthshire' => 'MON',
    'Montgomeryshire' => 'MGY',
    'Morayshire' => 'MOR',
    'Nairnshire' => 'NAI',
    'Norfolk' => 'NFK',
    'Northamptonshire' => 'NTH',
    'Northumberland' => 'NBL',
    'Nottinghamshire' => 'NTT',
    'Orkney' => 'OKI',
    'Oxfordshire' => 'OXF',
    'Peeblesshire' => 'PEE',
    'Pembrokeshire' => 'PEM',
    'Perthshire' => 'PER',
    'Renfrewshire' => 'RFW',
    'Radnorshire' => 'RAD',
    'Ross and Cromarty' => 'ROC',
    'Roxburghshire' => 'ROX',
    'Rutland' => 'RUT',
    'Sark' => 'SRK',
    'Selkirkshire' => 'SEL',
    'Shetland' => 'SHI',
    'Shropshire' => 'SAL',
    'Somerset' => 'SOM',
    'Staffordshire' => 'STS',
    'Stirlingshire' => 'STI',
    'Suffolk' => 'SFK',
    'Surrey' => 'SRY',
    'Sussex' => 'SSX',
    'Sutherland' => 'SUT',
    'Warwickshire' => 'WAR',
    'Westmorland' => 'WES',
    'West Lothian' => 'WLN',
    'Wigtownshire' => 'WIG',
    'Wiltshire' => 'WIL',
    'Worcestershire' => 'WOR',
    'Yorkshire, East Riding' => 'ERY',
    'Yorkshire, North Riding' => 'NRY',
    'Yorkshire, West Riding' => 'WRY',
   
    'England' => 'ENG',
    'Clwyd' => 'CWD',
    'Dyfed' => 'DFD',
    'Gwent' => 'GNT',
    'Gwynedd' => 'GWN',
    'Powys' => 'POW',
    'Mid Glamorgan' => 'MGM',
    'South Glamorgan' => 'SGM',
    'West Glamorgan' => 'WGM',
    'Wales' => 'WLS',
    'Borders' => 'BOR',
    'Central' => 'CEN',
    'Dumfries and Galloway' => 'DGY',
    'Grampian' => 'GMP',
    'Highland' => 'HLD',
    'Lothian' => 'LTN',
    'Orkney Isles' => 'OKI',
    'Shetland Isles' => 'SHI',
    'Strathclyde' => 'STD',
    'Tayside' => 'TAY',
    'Western Isles' => 'WIS',
    'Scotland' => 'SCT',
    'Unknown' => 'UNK'
  }
    
end