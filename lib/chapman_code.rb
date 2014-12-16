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
    'Bedfordshire' => 'BDF',
    'Berkshire' => 'BRK',
    'Buckinghamshire' => 'BKM',
    'Cambridgeshire' => 'CAM',
    'Channel Islands' => 'CHI',
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
    'Isle of Man' => 'IOM',
    'Isle of Wight' => 'IOW',
    'Kent' => 'KEN',
    'Lancashire' => 'LAN',
    'Leicestershire' => 'LEI',
    'Lincolnshire' => 'LIN',
    'City of London' => 'LND',
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
    'Yorkshire, West Riding' => 'WRY',
    'Alderney' => 'ALD',
    'Guernsey' => 'GSY',
    'Jersey' => 'JSY',
    'Sark' => 'SRK',
    'Aberdeenshire' => 'ABD',
    'Angus' => 'ANS',
    'Argyllshire' => 'ARL',
    'Ayrshire' => 'AYR',
    'Banffshire' => 'BAN',
    'Berwickshire' => 'BEW',
    'Bute' => 'BUT',
    'Caithness' => 'CAI',
    'Clackmannanshire' => 'CLK',
    'Dumfriesshire' => 'DFS',
    'Dunbartonshire' => 'DNB',
    'East Lothian' => 'ELN',
    'Fife' => 'FIF',
    'Angus' => 'ANS',
    'Fife' => 'FIF',
    'Inverness-shire' => 'INV',
    'Kincardineshire' => 'KCD',
    'Kinross-shire' => 'KRS',
    'Kirkcudbrightshire' => 'KKD',
    'Lanarkshire' => 'LKS',
    'Midlothian' => 'MLN',
    'Morayshire' => 'MOR',
    'Nairnshire' => 'NAI',
    'Orkney' => 'OKI',
    'Peeblesshire' => 'PEE',
    'Perthshire' => 'PER',
    'Renfrewshire' => 'RFW',
    'Ross and Cromarty' => 'ROC',
    'Roxburghshire' => 'ROX',
    'Selkirkshire' => 'SEL',
    'Shetland' => 'SHI',
    'Stirlingshire' => 'STI',
    'Sutherland' => 'SUT',
    'West Lothian' => 'WLN',
    'Wigtownshire' => 'WIG',
    'Anglesey' => 'AGY',
    'Brecknockshire' => 'BRE',
    'Caernarfonshire' => 'CAE',
    'Cardiganshire' => 'CGN',
    'Carmarthenshire' => 'CMN',
    'Denbighshire' => 'DEN',
    'Flintshire' => 'FLN',
    'Glamorgan' => 'GLA',
    'Merionethshire' => 'MER',
    'Monmouthshire' => 'MON',
    'Montgomeryshire' => 'MGY',
    'Pembrokeshire' => 'PEM',
    'Radnorshire' => 'RAD',
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