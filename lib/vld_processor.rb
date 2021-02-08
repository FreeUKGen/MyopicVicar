class VldProcessor


  VLD_RECORD_LENGTH = 299
  class << self

    def process(filename, chapman_code = nil, message_file)


      # open the file
      contents = []
      raw_file = File.read(filename)
      # loop through each 299-byte substring
      record_count = raw_file.length / VLD_RECORD_LENGTH
      computed_file_length = record_count * VLD_RECORD_LENGTH
      p "***Incorrect file length for #{filename}  Reported file size is #{File.size(filename)} bytes, number of characters read #{raw_file.length}, record count of #{record_count} giving computed length #{computed_file_length} " if raw_file.length != computed_file_length
      p "Correct file length for #{filename}  Reported file size is #{File.size(filename)} bytes, number of characters read #{raw_file.length}, record count of #{record_count} giving computed length #{computed_file_length} " if raw_file.length == computed_file_length#return contents if raw_file.length != computed_file_length

      (0...record_count).to_a.each do |i|
        contents << process_vld_record(raw_file[i*VLD_RECORD_LENGTH, VLD_RECORD_LENGTH], chapman_code, message_file )
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

    def process_vld_record(line, chapman_code = nil, message_file)
      record = parse_vld_record(line, message_file)
      record = clean_vld_record(record, chapman_code)
      record
    end

    def parse_vld_record(line, message_file)
      record = {}
      VLD_POSITION_MAP.each_pair do |attribute, location|
        record[attribute] = line[location[0],location[1]]
      end
      message_file.puts record
      record
    end

    def clean_vld_record(raw_record, chapman_code = nil)
      # trim trailing whitespace
      record = {}
      raw_record.each_pair do |key,value|
        clean_value = value.encode('ISO-8859-15', { :invalid => :replace, :undef => :replace, :replace => ''}).sub(/\s*$/, '')
        record[key] = clean_value unless clean_value.blank?
      end

      if chapman_code && record[:t_born_cty] == "INC"
        record[:t_born_cty] = chapman_code
      end
      if chapman_code && record[:born_cty] == "INC"
        record[:born_cty] = chapman_code
      end

      # fix schn over 1000
      if record[:sch_a] == "!"
        record[:sch_n] = (1000+record[:sch_n].to_i).to_s
      end

      record[:t_born_cty] = 'UNK' if record[:t_born_cty].blank?
      [:t_born_cty, :born_cty].each do |key|
        record[key] = 'WAL' if record[key] == 'WLS'#note: FC1 uses "WAL" instead of "WLS" but chapman_code.rg uses "WLS". should we be consistent going forward?
        record[key] = 'KCD' if record[key] == 'KIN'
      end

      record[:notes] = '' if record[:notes] =~ /\[see mynotes.txt\]/

      if record[:born_cty].blank?
        record[:born_cty] = record[:t_born_cty]
        record[:born_place] = record[:t_born_place]
      end

      # nil out blanks

      record
    end

    def check_vld_records_for_errors(records, chapman_code, vld_file_name)
      record_errors = []
      records.each_with_index do |rcd,idx|
        line_label = "#{chapman_code}/#{vld_file_name} entry #{idx}"
        entry_details = "ED:#{rcd[:enum_n] unless rcd[:enum_n].blank?}#{rcd[:enum_a] unless rcd[:enum_a].blank?} Schedule:#{rcd[:sch_n] unless rcd[:sch_n].blank?}#{rcd[:sch_a] unless rcd[:sch_a].blank?} Record:#{rcd[:seq_in_household] unless rcd[:seq_in_household].blank?}, #{rcd[:s_name] unless rcd[:s_name].blank?}, #{rcd[:f_name] unless rcd[:f_name].blank?}"
        if '-'==rcd[:prem_flag] || 'x'==rcd[:prem_flag]
          unless @@valid_birth_counties.include?(rcd[:born_cty])
            record_errors << "#{line_label}: Invalid birth county #{rcd[:born_cty] unless rcd[:born_cty].blank?} (#{entry_details})"
          end
          unless rcd[:age] =~ /^\s*\d+\s*$/
            record_errors << "#{line_label}: Invalid age #{rcd[:age] unless rcd[:age].blank?} (#{entry_details})"
          end
        end
      end
      record_errors
    end
  end
end
