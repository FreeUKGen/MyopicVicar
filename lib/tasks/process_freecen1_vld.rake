namespace :freecen do
  # see http://west-penwith.org.uk/fctools/doc/reference.html
  desc "Process legacy FreeCEN1 VLD files"
  task :process_freecen1_vld, [:filename] => [:environment] do |t, args| 
    process_vld_file(args.filename)

  end

  # TODO move to library
  
  def process_vld_file(filename)
    file_record = process_vld_filename(filename)
    entry_records = process_vld_contents(filename)
    
    persist_to_database(filename, file_record, entry_records)
  end

  def persist_to_database(filename, file_hash, entry_hash_array)
    file = Freecen1VldFile.new(file_hash)
    file.file_name = File.basename(filename)
    file.dir_name = File.basename(File.dirname(filename))
    file.save!
    
    entry_hash_array.each do |hash|
      entry = Freecen1VldEntry.new
    
      entry.deleted_flag = hash[:deleted_flag]

      entry.surname = hash[:s_name]
      entry.forenames = hash[:f_name]

      entry.occupation = hash[:occ]
      entry.occupation_flag = hash[:occ_err]
      
      entry.name_flag = hash[:name_err]
      entry.relationship = hash[:rel]
      entry.marital_status = hash[:m_stat]
      entry.sex = hash[:sex]
      entry.age = hash[:age]
      entry.age_unit = hash[:age_unit]
      entry.detail_flag = hash[:p_det_err]


      entry.civil_parish = hash[:parish]
      entry.ecclesiastical_parish = hash[:ecc_parish]

      entry.household_number = hash[:hh]
      entry.sequence_in_household = hash[:seq_in_household]

      entry.enumeration_district = "#{hash[:enum_n]}#{hash[:enum_a]}"
      entry.schedule_number = "#{hash[:sch_n]}#{hash[:sch_a]}"
      entry.folio_number = "#{hash[:fo_n]}#{hash[:fo_a]}" 
      entry.page_number = hash[:pg_n]
 
      entry.house_number = hash[:house_n] || hash[:house_a]
      entry.house_or_street_name = hash[:street]
      
      entry.uninhabited_flag = hash[:prem_flag]
      entry.unnocupied_notes = hash[:unoccupied_notes]
      
      entry.individual_flag = hash[:individual_flag]
      entry.birth_county = hash[:born_cty]
      entry.birth_place = hash[:born_place]
      entry.verbatim_birth_county = hash[:t_born_cty]
      entry.verbatim_birth_place = hash[:t_born_place]
      entry.birth_place_flag = hash[:place_err]
      entry.disability = hash[:dis]
      entry.language = hash[:language]
      entry.notes = hash[:notes]

      entry.entry_number = hash[:hh]

      entry.attributes.delete_if { |key,value| value.blank? }
      entry.freecen1_vld_file = file
      
      entry.save!
    end
  end

  def process_vld_filename(filepath)
        # $centype = substr($file,0,2);
    filename = File.basename(filepath)
    centype = filename[0,2]
        # if (uc($centype) eq "HO") {
    centype.upcase!
    if "HO" == centype
          
            # #process EW 1841-1851
            # $year = 1 if (substr($file,2,1) == 4 ||substr($file,2,1) == 1); 
            # $year = 2 if substr($file,2,1) == 5;
      year_stub = filename[2,1]
      year = 1 if year_stub == "4" || year_stub = "1"
      year = 2 if year_stub == "5"
            # $piece = substr($file,5,3);
            # $piece = substr($file,4,4) if substr($file,4,1) == 1 || substr($file,4,1) == 2;
      piece = filename[5,3]
      piece_stub = filename[4,1] 
      piece = filename[4,4] if piece_stub == "1" || piece_stub == "2"
            # $series = "ENW";
      series = "ENW"
      
        # } elsif (uc($centype) eq "HS") {
    elsif "HS" == centype
      
            # #process SC 1841-1851
            # $year = 1 if substr($file,2,1) == 4;
            # $year = 2 if substr($file,2,1) == 5;
      year_stub = filename[2,1]
      year = 1 if year_stub == "4" 
      year = 2 if year_stub == "5"
            # $piece = substr($file,5,3);
      piece = filename[5,3]
            # $sctpar = substr($file,3,2);
            # $series = "SCT";
      sctpar = filename[3,2] # what is this used for?
      series = "SCT"
        # } elsif (uc($centype) eq "RG") {
    elsif "RG" == centype
      
            # #process EW 1861-1891
      year_stub = filename[2,2]
            # $year = 3 if substr($file,2,2) eq '09';
      year = 3 if year_stub == '09'
            # $year = 4 if substr($file,2,2) eq '10';
      year = 4 if year_stub == '10'
            # $year = 5 if substr($file,2,2) eq '11';
      year = 5 if year_stub == '11'
            # $year = 6 if substr($file,2,2) eq '12';
      year = 6 if year_stub == '12'
            # $year = 7 if substr($file,2,2) eq '13';
      year = 7 if year_stub == '13'
            # $year = 8 if substr($file,2,2) eq '14';
      year = 8 if year_stub == '14'
            # $series = "ENW";
      series = 'ENW'
            # $piece = substr($file,4,4);
      piece = filename[4,4]
        # } elsif (uc($centype) eq "RS") {
    elsif "RS" == centype
            # #process SC 1861-1891
      year_stub = filename[2,1]
            # $year = 3 if substr($file,2,1) == 6;
      year = 3 if year_stub == '6'
            # $year = 4 if substr($file,2,1) == 7;
      year = 4 if year_stub == '7'
            # $year = 5  if substr($file,2,1) == 8;
      year = 5 if year_stub == '8'
            # $year = 6 if substr($file,2,1) == 9;
      year = 6 if year_stub == '9'
            # $year = 6 if substr($file,2,1) == 0;
      year = 6 if year_stub == '0'
            # $year = 6 if substr($file,2,1) == 1;
      year = 6 if year_stub == '1'
            # $sctpar = substr($file,3,2);
      sctpar = filename[3,2]
            # $series = "SCT";
      series = 'SCT'
            # $piece = substr($file,5,3);
      piece = filename[5,3]
        # } else {
    else
      print "Invalid Census Type in file #{filename}\n"
            # print E "<tr><td>".substr($dirname,-3)."<td>$file<td>Invalid Census Type";
            # next;
            
        # }
        
    end
        # $suffix = "";
        # if ($series eq 'SCT') {
            # $sql = "SELECT Suffix from Pieces WHERE Country = 'SCT' AND Piece = '$piece' AND Parish = '$sctpar' AND Year = '$year'";
            # my @sfx = $dbh->selectrow_array($sql);
      # $suffix = $sfx[0];
        # }
        # $fullyear = $year*10 + 1831;
        
    full_year = year*10 + 1831
    
    {:full_year => full_year, :raw_year => year, :piece => piece, :series => series, :census_type => centype }
  end
  
  VLD_RECORD_LENGTH = 299
  
  def process_vld_contents(filename)
    # open the file
    raw_file = File.read(filename)
    # loop through each 299-byte substring
    record_count = raw_file.length / VLD_RECORD_LENGTH
    contents = []
    (0...record_count).to_a.each do |i|
      contents << process_vld_record(raw_file[i*VLD_RECORD_LENGTH, VLD_RECORD_LENGTH])
    end
    
    contents
  end
# 
# 
# A       0  1 Deletion marker (D or blank)
# B       1  4 Not used. Was Registration district - this usage is discontinued.
# C       5  6 A six digit number (leading zeros) which counts the households
# D      11  4 A four digit number (leading zeros) which counts members in each
             # household
# E   A  15 20 Parish name (I don't check this, it is up to you to get it right!)
# F   B  35  4 Enumeration district (3n+1a, the remaining numeric fields have
             # trailing spaces)
# G   C  39  5 Folio number (4n+1a)
# H   D  44  4 Page number (4n)
# I   E  48  4 Schedule number (3n+1a)
# J   F  52  5 House number (4n+1a)
# K   G  57 30 House/Street name (default -)
# L   H  87  1 Uninhabited flag (b, u, v, n, x or -)
# M   I  88 24 Surname (capitals, default -)
# N   J 112 24 Forenames (default -)
# O   K 136  1 Flag for name fields (x or -)
# P   L 137  6 Relationship (default -)
# Q   M 143  1 Condition (M, S, U, W or -)
# R   N 144  1 Sex (M, F or -)
# S   O 145  3 Age (no default but 999=unknown/unreadable)
      # 148  1 Age unit(y, m, w, d or -)
# T   P 149  1 Flag for detail fields i.e. rel/cond/sex/age (x or -)
# U   Q 150 30 Occupation
    # R        Employed Status (extracted from occupation field)
# V   S 180  1 Flag for occupation (x or -)
# W   T 181  3 County code (3a capitals, no default but UNK if not known)
# X   U 184 20 Birth place (default -)
# Y   V 204  1 Flag for birth place (x or -)
# Z   W 205  6 Disability (default blank)
# AA  X 211  1 Language (W, E, B, G or blank)
# AB  Y 212 44 Notes (default blank, no case 


  VLD_POSITION_MAP = 
  {
    :deleted_flag => [0,1],
    :hh => [5,6],
    :suffix => [1,3],
    :parish => [15,20],
    :enum_n => [35,3],
    :enum_a => [38,1],
    :sch_n => [48,3],
    :sch_a => [51,1],
    :house_n => [52,4],
    :house_a => [56,1],
    :street => [57,30],
    :prem_flag => [87,1],
    :ecc_parish => [256,20],
    :individual_flag => [87,1],
    :seq_in_household => [11,4],
    :s_name => [88,24],
    :f_name => [112,24],
    :name_err => [136,1],
    :rel => [137,6],
    :m_stat => [143,1],
    :sex => [144,1],
    :age => [145,3],
    :age_unit => [148,1],
    :p_det_err => [149,1],
    :occ => [150,30],
    :occ_err => [180,1],
    :t_born_cty => [181,3],
    :t_born_place => [184,20],
    :place_err => [204,1],
    :dis => [205,6],
    :language => [211,1],
    :notes => [212,44],
    :born_cty => [276,3],
    :born_place => [279,20],
    :fo_n => [39,4],
    :fo_a => [43,1],
    :pg_n => [44,4],
    # :s_name_sx => [88,24], # original has soundex of iu1
    # :born_place_sx => [279,20], #original has soundex of iu19
    :unoccupied_notes => [212,44],
  }
  

  
  def process_vld_record(line)
    record = parse_vld_record(line)
    record = clean_vld_record(record)
    
    record
  end
  
  def parse_vld_record(line)
    record = {}
    VLD_POSITION_MAP.each_pair do |attribute, location|
      record[attribute] = line[location[0],location[1]]
    end

    record
  end
  
  def clean_vld_record(raw_record)
    # trim trailing whitespace
    
    record = {}
    raw_record.each_pair do |key,value|
      clean_value = value.sub(/\s*$/, '')
      record[key] = clean_value unless clean_value.blank?       
    end
    
    # fix schn over 1000
    if record[:sch_a] == "!"
      record[:sch_n] = (1000+record[:sch_n]).to_s
    end
        
    [:t_born_cty, :born_cty].each do |key|
      record[key] = 'WAL' if record[key] == 'WLS'
      record[key] = 'KCD' if record[key] == 'KIN'
      record[key] = 'UNK' if record[key] == ''
    end

    record[:notes] = '' if record[:notes] =~ /\[see mynotes.txt\]/
  
    # nil out blanks
    
    record
  end
end

