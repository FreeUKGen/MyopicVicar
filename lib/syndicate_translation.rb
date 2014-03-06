module SyndicateTranslation
 def self.name_from_code(code)
    CODES.invert[code]
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
  
  def self.select_hash_with_parenthetical_codes
    Hash[ChapmanCode::CODES.map { |k,v| ["#{k} (#{v})", v] }]
  end

  def self.has_key(value)
    CODES.key(value)
  end

  def self.value?(value)
    CODES.value?(value)  
  end
	
CODES = {'nil' => 'Unknown',
'ABD' => 'Aberdeenshire',
'AGY' => 'Wales',
'ALD' => 'Channel Islands',
'ANS' => 'Forfarshire (Angus)',
'ANT' => 'Ireland',
'ARL' => 'Argyllshire',
'ARM' => 'Ireland',
'AYR' => 'Ayrshire',
'BAN' => 'Banffshire',
'BDF' => 'Bedfordshire',
'BEW' => 'Berwickshire',
'BKM' => 'Buckinghamshire',
'BRE' => 'Wales',
'BRK' => 'Berkshire',
'BUT' => 'Bute',
'CAE' => 'Caernarvonshire',
'CAI' => 'Caithness-shire',
'CAR' => 'Ireland',
'CAV' => 'Ireland',
'CAM' => 'Cambridgeshire',
'CGN' => 'Wales',
'CHI' => 'Channel Islands',
'CHS' => 'Cheshire',
'CLA' => 'Ireland',
'CLK' => 'Rest of Scotland',
'CMN' => 'Wales',
'CON' => 'Rest of England',
'CUL' => 'Cumberland',
'COR' => 'Ireland',
'DBY' => 'Rest of England',
'DNB' => 'Rest of Scotland',
'DEN' => 'Wales',
'DEV' => 'Devon',
'DON' => 'Ireland',
'DFS' => 'Rest of Scotland',
'DOR' => 'Dorset',
'DOW' => 'Ireland',
'DUB' => 'Ireland',
'DUR' => 'Durham',
'ELN' => 'East Lothian',
'ENG' => 'Rest of England',
'ERY' => 'Rest of England',
'ESS' => 'Essex',
'FER' => 'Ireland',
'FIF' => 'Rest of Scotland',
'FLN' => 'Wales',
'GAL' => 'Ireland',
'GLA' => 'Wales',
'GLS' => 'Gloucestershire',
'GSY' => 'Channel Islands',
'HAM' => 'Hampshire',
'HEF' => 'Herefordshire',
'HRT' => 'Hertfordshire',
'HUN' => 'Huntingdonshire',
'INV' => 'Inverness-shire',
'IOM' => 'Isle of Man',
'IOW' => 'Isle of Wight',
'IRL' => 'Ireland',
'JSY' => 'Channel Islands',
'KCD' => 'Rest of Scotland',
'KRS' => 'Rest of Scotland',
'KEN' => 'Kent',
'KER' => 'Ireland',
'KID' => 'Ireland',
'KIK' => 'Ireland',
'KKD' => 'Rest of Scotland',
'LAN' => 'Lancashire',
'LDY' => 'Ireland',
'LEI' => 'Leicestershire',
'LET' => 'Ireland',
'LEX' => 'Ireland',
'LIM' => 'Ireland',
'LIN' => 'Lincolnshire',
'LKS' => 'Rest of Scotland',
'LND' => 'London City',
'LOG' => 'Ireland',
'LOU' => 'Ireland',
'MAY' => 'Ireland',
'MDX' => 'Middlesex',
'MEA' => 'Ireland',
'MER' => 'Merionethshire',
'MGY' => 'Wales',
'MLN' => 'Rest of Scotland',
'MOG' => 'Ireland',
'MON' => 'Wales',
'MOR' => 'Rest of Scotland',
'NAI' => 'Rest of Scotland',
'NBL' => 'Northumberland',
'NFK' => 'Norfolk',
'NRY' => 'North Riding Yorkshire',
'NTH' => 'Northamptonshire',
'NTT' => 'Nottinghamshire',
'OFF' => 'Ireland',
'OKI' => 'Orkney Isles',
'OVB' => 'Overseas',
'OVF' => 'Overseas',
'OXF' => 'Oxfordshire',
'PEE' => 'Peebles',
'PEM' => 'Wales',
'PER' => 'Rest of Scotland',
'RAD' => 'Wales',
'RFW' => 'Rest of Scotland',
'ROC' => 'Rest of Scotland',
'ROS' => 'Ireland',
'ROX' => 'Rest of Scotland',
'RUT' => 'Rutland',
'SCT' => 'Rest of Scotland',
'SEL' => 'Rest of Scotland',
'SAL' => 'Shropshire',
'SFK' => 'Suffolk',
'SHI' => 'Rest of Scotland',
'SLI' => 'Ireland',
'SOM' => 'Somerset',
'SRK' => 'Channel Islands',
'SRY' => 'Surrey',
'SSX' => 'Sussex',
'STI' => 'Rest of Scotland',
'STS' => 'Staffordshire',
'SUT' => 'Sutherland',
'TIP' => 'Ireland',
'TYR' => 'Ireland',
'UNK' => 'Unknown',
'WAR' => 'Warwickshire',
'WAT' => 'Ireland',
'WEM' => 'Ireland',
'WES' => 'Rest of England',
'WEX' => 'Ireland',
'WIC' => 'Ireland',
'WIG' => 'Rest of Scotland',
'WIL' => 'Wiltshire',
'WLN' => 'Rest of Scotland',
'WLS' => 'Wales',
'WOR' => 'Worcestershire',
'WRY' => 'West Riding Yorkshire',
'YKS' => 'Yorkshire'
}
end