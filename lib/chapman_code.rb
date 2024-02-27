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
  require 'freereg_options_constants'
  require 'freecen_constants'
  require 'app'
  ###################
  # Note the actual list of codes is the merge_counties or select_hash
  #######################
  class << self

    def add_parenthetical_codes(hash)
      hsh = {}
      hash.each_pair do |key, value|
        hsh[key] = Hash[value.map { |k, v|
          if v.include?(" ")
            ["#{k} (#{v[0..6]} etc.)", v]
          else
            ["#{k} (#{v})", v]
          end
        }]
      end
      hsh
    end

    def code_from_name(name)
      codes = merge_countries
      codes[name]
    end

    def codes_for_cen_birth_county
      # this is used in the birth county selection BUT ITS THE SAME as codes_for_cen_county
      hsh = {}
      codes = ChapmanCode.remove_codes(ChapmanCode::CODES)
      codes.each_pair do |ctry, ctryval|
        ctryhash = {}
        ctryval.each_pair do |kk, vv|
          ctryhash[kk] = vv unless %w[ERY NRY WRY].include?(vv)
        end
        hsh[ctry] = ctryhash
      end
      hsh
    end

    def freecen_birth_codes
      ChapmanCode.values
    end

    def codes_for_cen_county
      # This is used in the county selection
      hsh = {}
      codes = ChapmanCode.remove_codes(ChapmanCode::CODES)
      codes.each_pair do |ctry, ctryval|
        ctryhash = {}
        ctryval.each_pair do |kk, vv|
          ctryhash[kk] = vv unless %w[ALD GSY JSY SRK].include?(vv.to_s)
        end
        hsh[ctry] = ctryhash
      end
      hsh
    end

    def codes_for_cen_county_search
      hsh = {}
      codes = ChapmanCode.remove_codes(ChapmanCode::CODES)
      codes.each_pair do |ctry, ctryval|
        ctryhash = {}
        ctryval.each_pair do |kk, vv|
          if Rails.application.config.freecen2_place_cache
            ctryhash[kk] = vv unless %w[ALD GSY JSY SRK].include?(vv.to_s) || CODES['Ireland'].values.include?(vv.to_s) ||
              JSON.parse(Freecen2PlaceCache.find_by(chapman_code: vv.to_s).places_json).with_indifferent_access.blank?
          else
            ctryhash[kk] = vv unless %w[ALD GSY JSY SRK].include?(vv.to_s) || CODES['Ireland'].values.include?(vv.to_s)
          end
        end
        hsh[ctry] = ctryhash
      end
      hsh
    end

    def chapman_codes_for_reg_county
      codes = ChapmanCode.remove_codes(ChapmanCode::CODES)
      all_codes = []
      codes.each_pair do |_key, value|
        value.each_value do |actual_value|
          all_codes << actual_value
        end
      end
      all_codes
    end

    def has_key(value)
      codes = merge_countries
      codes.key(value)
    end

    def has_key?(code)
      codes = merge_countries
      codes.key?(code)
    end

    def keys
      codes = merge_countries
      mine = []
      codes.each_key do |k|
        mine << k
      end
      mine
    end

    def merge_countries
      all_countries = {}
      ChapmanCode::CODES.each_key do |key|
        all_countries.merge!(CODES[key])
      end
      all_countries
    end

    # Note the actual list of codes is the merge_counties or select_hash
    def merge_counties
      all_counties = County.distinct(:chapman_code)
      all_counties
    end

    def name_from_code(code)
      codes = {}
      App.name_downcase == 'freebmd' ? code_hash = ChapmanCode::FREEBMD_CODES : code_hash = ChapmanCode::CODES
      code_hash.each_value do |country_value|
        country_value.each_pair do |county_key, county_value|
          codes[county_value] = county_key
        end
      end
      result = codes[code]
      result
    end

    def remove_codes(original_hash)
      reduced_hash = {}
      original_hash.each_pair do |key, value|
        case App.name_downcase
        when 'freereg'
          elimination_codes = FreeregOptionsConstants::CHAPMAN_CODE_ELIMINATIONS
        when 'freecen'
          elimination_codes = Freecen::CHAPMAN_CODE_ELIMINATIONS
        when 'freebmd'
          elimination_codes = {}
        end
        myvalue = value.dup
        elimination_codes.each do |county|
          myvalue.delete_if { |new_key, _new_value| new_key == county }
        end
        reduced_hash[key] = myvalue
      end
      reduced_hash
    end

    def select_hash
      codes = merge_countries
      codes
    end

    def select_hash_with_parenthetical_codes
      hash = ChapmanCode::CODES.each_pair do |key, value|
        ChapmanCode::CODES[key] = Hash[value.map { |k, v| ["#{k} (#{v})", v] }]
      end
      hash
    end

    def value?(value)
      codes = merge_countries
      codes.value?(value)
    end

    def values
      codes = merge_countries
      codes.values
    end

    def values_at(value)
      codes = merge_countries
      array = codes.values_at(value)
      array[0]
    end
  end

  CODES = {
    'England' => {
      'England' => 'ENG',
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
      'Yorkshire, West Riding' => 'WRY'
    }.freeze,
    'Ireland' => {
      'Ireland' => 'IRL',
      'County Antrim' => 'ANT',
      'County Armagh' => 'ARM',
      'County Carlow' => 'CAR',
      'County Cavan' => 'CAV',
      'County Clare' => 'CLA',
      'County Cork' => 'COR',
      'County Donegal' => 'DON',
      'County Down' => 'DOW',
      'County Dublin' => 'DUB',
      'County Fermanagh' => 'FER',
      'County Galway' => 'GAL',
      'County Kerry' => 'KER',
      'County Kildare' => 'KID',
      'County Kilkenny' => 'KIK',
      'County Leitrim' => 'LET',
      'County Laois' => 'LEX',
      'County Limerick' => 'LIM',
      'County Londonderry ' => 'LDY',
      'County Longford' => 'LOG',
      'County Louth' => 'LOU',
      'County Mayo' => 'MAY',
      'County Meath' => 'MEA',
      'County Monaghan' => 'MOG',
      'County Offaly' => 'OFF',
      'County Roscommon' => 'ROS',
      'County Sligo' => 'SLI',
      'County Tipperary' => 'TIP',
      'County Tyrone' => 'TYR',
      'County Waterford' => 'WAT',
      'County Westmeath' => 'WEM',
      'County Wexford' => 'WEX',
      'County Wicklow' => 'WIC'
    }.freeze,
    'Islands' => {
      'Channel Islands' => 'CHI',
      'Alderney' => 'ALD',
      'Guernsey' => 'GSY',
      'Jersey' => 'JSY',
      'Isle of Man' => 'IOM',
      'Sark' => 'SRK'
    }.freeze,
    'Scotland' => {
      'Scotland' => 'SCT',
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
      'Wigtownshire' => 'WIG'
    }.freeze,
    'Wales' => {
      'Wales' => 'WLS',
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
      'Radnorshire' => 'RAD'
    }.freeze,
    'Special' => {
      'Unknown' => 'UNK',
      'England and Wales Shipping' => 'EWS',
      'Out of County' => 'OUC',
      'Overseas British' => 'OVB',
      'Overseas Foreign' => 'OVF',
      'Scottish Shipping' => 'SCS',
      'Other Locations' => 'OTH',
      'Royal Navy Ships' => 'RNS',
      'Military' => 'MIL'
    }.freeze
  }.freeze

  FREEBMD_CODES = {
    'England' => {
      "All England" => "AVN BDF BRK BKM CAM CHS CLV DUR CON CUL CMA DBY DEV DOR ERY SXE ESS GLS GTL GTM HAM HWR HEF HRT HUM HUN IOW KEN LAN LEI LIN LND MSY MDX NFK NRY NYK NTH NBL NTT OXF RUT SAL SOM SYK STS SFK SRY SSX TWR WAR WMD WRY SXW WYK WES WIL WOR",
      "Avon (from Jun1974)" => "AVN",
      "Bedfordshire" => "BDF",
      "Berkshire" => "BRK",
      "Buckinghamshire" => "BKM",
      "Cambridgeshire" => "CAM",
      "Cheshire" => "CHS",
      "Cleveland (from Jun1974)" => "CLV",
      "Co. Durham" => "DUR",
      "Cornwall" => "CON",
      "Cumberland (to Mar1974)" => "CUL",
      "Cumbria (from Jun1974)" => "CMA",
      "Derbyshire" => "DBY",
      "Devon" => "DEV",
      "Dorset" => "DOR",
      "East Riding of Yorkshire (to Mar1974)" => "ERY",
      "East Sussex (from Jun1974)" => "SXE",
      "Essex" => "ESS",
      "Gloucestershire" => "GLS",
      "Greater London (from Jun1965)" => "GTL",
      "Greater Manchester (from Jun1974)" => "GTM",
      "Hampshire" => "HAM",
      "Hereford and Worcester (from Jun1974)" => "HWR",
      "Herefordshire (to Mar1974)" => "HEF",
      "Hertfordshire" => "HRT",
      "Humberside (from Jun1974)" => "HUM",
      "Huntingdonshire (to Mar1974)" => "HUN",
      "Isle of Wight (from Sep1946)" => "IOW",
      "Kent" => "KEN",
      "Lancashire" => "LAN",
      "Leicestershire" => "LEI",
      "Lincolnshire" => "LIN",
      "London (to Mar1965)" => "LND",
      "Merseyside (from Jun1974)" => "MSY",
      "Middlesex (to Mar1965)" => "MDX",
      "Norfolk" => "NFK",
      "North Riding of Yorkshire (to Mar1974)" => "NRY",
      "North Yorkshire (from Jun1974)" => "NYK",
      "Northamptonshire" => "NTH",
      "Northumberland" => "NBL",
      "Nottinghamshire" => "NTT",
      "Oxfordshire" => "OXF",
      "Rutland (to Mar1974)" => "RUT",
      "Shropshire" => "SAL",
      "Somerset" => "SOM",
      "South Yorkshire (from Jun1974)" => "SYK",
      "Staffordshire" => "STS",
      "Suffolk" => "SFK",
      "Surrey" => "SRY",
      "Sussex (to Mar1974)" => "SSX",
      "Tyne and Wear (from Jun1974)" => "TWR",
      "Warwickshire" => "WAR",
      "West Midlands (from Jun1974)" => "WMD",
      "West Riding of Yorkshire (to Mar1974)" => "WRY",
      "West Sussex (from Jun1974)" => "SXW",
      "West Yorkshire (from Jun1974)" => "WYK",
      "Westmorland (to Mar1974)" => "WES",
      "Wiltshire" => "WIL",
      "Worcestershire (to Mar1974)" => "WOR"
    }.freeze,
    'Wales' => {
      "All Wales" => "AGY BRE CAE CGN CMN CWD DEN DFD FLN GLA GNT GWN MER MGM MON MGY PEM POW RAD SGM WGM",
      "Anglesey (to Mar1974)" => "AGY",
      "Breconshire (to Mar1974)" => "BRE",
      "Caernarvonshire (to Mar1974)" => "CAE",
      "Cardiganshire (to Mar1974)" => "CGN",
      "Carmarthenshire (to Mar1974)" => "CMN",
      "Clwyd (from Jun1974)" => "CWD",
      "Denbighshire (to Mar1974)" => "DEN",
      "Dyfed (from Jun1974)" => "DFD",
      "Flintshire (to Mar1974)" => "FLN",
      "Glamorgan (to Mar1974)" => "GLA",
      "Gwent (from Jun1974)" => "GNT",
      "Gwynedd (from Jun1974)" => "GWN",
      "Merionethshire (to Mar1974)" => "MER",
      "Mid Glamorgan (from Jun1974)" => "MGM",
      "Monmouthshire (to Mar1974)" => "MON",
      "Montgomeryshire (to Mar1974)" => "MGY",
      "Pembrokeshire (to Mar1974)" => "PEM",
      "Powys (from Jun1974)" => "POW",
      "Radnorshire (to Mar1974)" => "RAD",
      "South Glamorgan (from Jun1974)" => "SGM",
      "West Glamorgan (from Jun1974)" => "WGM"
    }.freeze
  }.freeze
end
