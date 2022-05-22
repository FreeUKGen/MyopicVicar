module Freecen
  class Freecen1VldParser

    # Most of this is the original monthly update code with mods to accommodate uploading

    #note: FC1 uses "WAL" instead of "WLS" but chapman_code.rg uses "WLS"
    @@valid_birth_counties = ChapmanCode::values + ["ANT", "ARM", "AVN", "CAR", "CAV", "CLA", "CLV", "CMA", "CNN", "COR", "DON", "DOW", "DUB", "ENW", "FER", "GAL", "GTL", "GTM", "HUM", "HWR", "IRL", "KER", "KID", "KIK", "LDY", "LEN", "LET", "LEX", "LIM", "LOG", "LOU", "MAY", "MEA", "MOG", "MSY", "MUN", "NIR", "NYK", "OFF", "ROS", "SLI", "SXE", "SXW", "SYK", "TIP", "TWR", "TYR", "UIE", "WAL", "WAT", "WEM", "WEX", "WIC", "WMD", "WYK"] # adding all chapman codes listed in the FreeUKGENconst mysql database that weren't in ChapmanCode::values. ('OUC','OVF','OVB','UNK' are already in ChapmanCode::values). Do we want to flag these birth counties that are inconsistent with FC1?
    def initialize(print_performance=false)
      @print_performance = print_performance
    end

    def process_vld_file(filename, userid)
      chapman_code = File.basename(File.dirname(filename))
      chapman_code = chapman_code.sub(/-.*/, '')
      file_record = process_vld_filename(filename)
      entry_records = process_vld_contents(filename, chapman_code)
      start_time = Time.now
      print("   call check_vld_records_for_errors() #{start_time.strftime("%I:%M:%S %p")}\n") if @print_performance
      entry_errors = check_vld_records_for_errors(entry_records, chapman_code, File.basename(filename))
      print("  #{Time.now - start_time} elapsed\n") if @print_performance
      # do not persist if piece not found. raise exception so we can notify
      # person loading the files that either the PARMS.DAT or .VLD file needs
      # to be fixed
      start_time = Time.now
      print("   call FreecenPiece.where() #{start_time.strftime("%I:%M:%S %p")}") if @print_performance
      piece = FreecenPiece.find_by(:year => file_record[:full_year], :chapman_code => chapman_code, :piece_number => file_record[:piece], :parish_number => file_record[:sctpar])
      if piece.blank?
        raise "***No FreecenPiece found for chapman code #{chapman_code} and piece number #{file_record[:piece]} parish_number #{file_record[:sctpar]}. year=#{file_record[:full_year]} file=#{filename}\nVerify that the PARMS.DAT file is correct and has been loaded by the update task, verify that the .VLD file is in the correct directory and named correctly.\n"
      end
      print("  #{Time.now - start_time} elapsed\n") if @print_performance

      start_time = Time.now
      print("   call vldparser persist_to_database #{start_time.strftime("%I:%M:%S %p")}") if @print_performance
      file = persist_to_database(filename, file_record, entry_records, entry_errors, piece.id, userid)
      print("  #{Time.now - start_time} elapsed\n") if @print_performance

      return file, entry_records.length
    end

    def persist_to_database(filename, file_hash, entry_hash_array, entry_errors, piece_id, userid)
      dir_name = File.basename(File.dirname(filename))
      file_name = File.basename(filename)
      file = Freecen1VldFile.find_by(dir_name: dir_name, file_name: file_name)
      file_location = File.join(Rails.application.config.vld_file_locations, dir_name, file_name)
      if File.file?(file_location)
        # removes existing records; search records are deleted at same time as entries by call back
        Freecen1VldFile.delete_freecen1_vld_entries(dir_name, file_name)
        Freecen1VldFile.delete_dwellings(dir_name, file_name)
        Freecen1VldFile.delete_individuals(dir_name, file_name)
        Freecen1VldFile.delete_file_errors(dir_name, file_name)
      end
      if file.present? && file.freecen_piece.present?
        piece = file.freecen_piece
        piece.update_attributes(num_dwellings: 0, num_individuals: 0, freecen1_filename: '', status: '') if piece.present?
      elsif file.present?
        piece = FreecenPiece.find_by(file_name: file.file_name, dir_name: dir_name)
        piece.update_attributes(num_dwellings: 0, num_individuals: 0, freecen1_filename: '', status: '') if piece.present?
        file.update_attributes(freecen_piece_id: piece.id)
      else
        file = Freecen1VldFile.new(file_hash)
        file.action = 'Upload'
        file.userid = userid
        file.file_name = File.basename(filename)
        file.dir_name = File.basename(File.dirname(filename))
        file.freecen_piece_id = piece_id if piece_id.present?
        file.file_errors = entry_errors if entry_errors.present?
        file.num_entries = entry_hash_array.length
        file.save!
      end
      entries_to_insert = []
      entry_hash_array.each do |hash|
        entry = Freecen1VldEntry.new

        entry.deleted_flag = hash[:deleted_flag].encode("UTF-8", "iso-8859-1") unless hash[:deleted_flag].blank?

        entry.surname = hash[:s_name].encode("UTF-8", "iso-8859-1") unless hash[:s_name].blank?
        entry.forenames = hash[:f_name].encode("UTF-8", "iso-8859-1") unless hash[:f_name].blank?

        entry.occupation = hash[:occ].encode("UTF-8", "iso-8859-1") unless hash[:occ].blank?
        entry.occupation_flag = hash[:occ_err].encode("UTF-8", "iso-8859-1") unless hash[:occ_err].blank?

        entry.name_flag = hash[:name_err].encode("UTF-8", "iso-8859-1") unless hash[:name_err].blank?
        entry.relationship = hash[:rel].encode("UTF-8", "iso-8859-1") unless hash[:rel].blank?
        entry.marital_status = hash[:m_stat].encode("UTF-8", "iso-8859-1") unless hash[:m_stat].blank?
        entry.sex = hash[:sex].encode("UTF-8", "iso-8859-1") unless hash[:sex].blank?
        entry.age = hash[:age].encode("UTF-8", "iso-8859-1") unless hash[:age].blank?
        entry.age_unit = hash[:age_unit].encode("UTF-8", "iso-8859-1") unless hash[:age_unit].blank?
        entry.detail_flag = hash[:p_det_err].encode("UTF-8", "iso-8859-1") unless hash[:p_det_err].blank?

        entry.civil_parish = hash[:parish].encode("UTF-8", "iso-8859-1") unless hash[:parish].blank?
        entry.ecclesiastical_parish = hash[:ecc_parish].encode("UTF-8", "iso-8859-1") unless hash[:ecc_parish].blank?

        entry.dwelling_number = hash[:hh].encode("UTF-8", "iso-8859-1") unless hash[:hh].blank?
        entry.sequence_in_household = hash[:seq_in_household].encode("UTF-8", "iso-8859-1") unless hash[:seq_in_household].blank?

        entry.enumeration_district = "#{hash[:enum_n]}#{hash[:enum_a]}"
        entry.schedule_number = "#{hash[:sch_n]}#{hash[:sch_a]}"
        entry.folio_number = "#{hash[:fo_n]}#{hash[:fo_a]}"
        entry.page_number = hash[:pg_n].encode("UTF-8", "iso-8859-1") unless hash[:pg_n].blank?

        entry.house_number = hash[:house_n] || hash[:house_a]

        entry.house_number = entry.house_number.encode("UTF-8", "iso-8859-1") unless entry.house_number.blank?

        entry.house_or_street_name = hash[:street].encode("UTF-8", "iso-8859-1") unless hash[:street].blank?

        entry.uninhabited_flag = hash[:prem_flag].encode("UTF-8", "iso-8859-1") unless hash[:prem_flag].blank?
        entry.unoccupied_notes = hash[:unoccupied_notes].encode("UTF-8", "iso-8859-1") unless hash[:unoccupied_notes].blank?

        entry.individual_flag = hash[:individual_flag].encode("UTF-8", "iso-8859-1") unless hash[:individual_flag].blank?
        entry.birth_county = hash[:born_cty].encode("UTF-8", "iso-8859-1") unless hash[:born_cty].blank?
        entry.birth_place = hash[:born_place].encode("UTF-8", "iso-8859-1") unless hash[:born_place].blank?
        entry.verbatim_birth_county = hash[:t_born_cty].encode("UTF-8", "iso-8859-1") unless hash[:t_born_cty].blank?
        entry.verbatim_birth_place = hash[:t_born_place].encode("UTF-8", "iso-8859-1") unless hash[:t_born_place].blank?
        entry.birth_place_flag = hash[:place_err].encode("UTF-8", "iso-8859-1") unless hash[:place_err].blank?
        entry.disability = hash[:dis].encode("UTF-8", "iso-8859-1") unless hash[:dis].blank?
        entry.language = hash[:language].encode("UTF-8", "iso-8859-1") unless hash[:language].blank?
        entry.notes = hash[:notes].encode("UTF-8", "iso-8859-1") unless hash[:notes].blank?

        entry.attributes.delete_if { |key,value| value.blank? }
        entry.freecen1_vld_file = file

        entries_to_insert << entry.attributes
      end

      Freecen1VldEntry.collection.insert_many(entries_to_insert)

      file
    end

    def process_vld_filename(filepath)
      # $centype = substr($file,0,2);
      filename = File.basename(filepath)
      file_digest = Digest::MD5.file(filepath).to_s rescue nil
      centype = filename[0,2]
      # if (uc($centype) eq "HO") {
      centype.upcase!
      if "HO" == centype #HO = England & Wales, 1841 & 1851

        # #process EW 1841-1851
        # $year = 1 if (substr($file,2,1) == 4 ||substr($file,2,1) == 1);
        # $year = 2 if substr($file,2,1) == 5;
        year_stub = filename[2,1]
        year = 1 if year_stub == "4" || year_stub == "1"
        year = 2 if year_stub == "5"
        # $piece = substr($file,5,3);
        # $piece = substr($file,4,4) if substr($file,4,1) == 1 || substr($file,4,1) == 2;
        piece = filename[5,3]
        piece_stub = filename[4,1]
        piece = filename[4,4] if piece_stub == "1" || piece_stub == "2"
        # $series = "ENW";
        series = "ENW"

        # } elsif (uc($centype) eq "HS") {
      elsif "HS" == centype #HS = Scotland, 1841 & 1851

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
        sctpar = filename[3,2] # this is parish_number for scotland split files
        series = "SCT"
        # } elsif (uc($centype) eq "RG") {
      elsif "RG" == centype #RG = England & Wales, 1861 onwards

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
      elsif "RS" == centype #RS = Scotland, 1861 onwards
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
        # print "Invalid Census Type in file #{filename}\n"
        raise "***Invalid Census Type (#{centype.nil? ? 'nil' : centype}) in file #{filename}.\n"
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
      sctpar = sctpar.to_i
      sctpar = nil if 0==sctpar
      {:full_year => full_year, :raw_year => year, :piece => piece.to_i, :series => series, :census_type => centype, :sctpar => sctpar, :file_digest => file_digest }
    end

    VLD_RECORD_LENGTH = 299

    def process_vld_contents(filename, chapman_code = nil)
      # open the file
      contents = []
      raw_file = File.read(filename, :encoding => 'iso-8859-1')
      # loop through each 299-byte substring
      record_count = raw_file.length / VLD_RECORD_LENGTH
      computed_file_length = record_count * VLD_RECORD_LENGTH
      p  "***Incorrect file length for #{filename}  Actual #{File.size(filename)} measured #{raw_file.length} Computed #{computed_file_length} " if raw_file.length != computed_file_length
      # return contents if raw_file.length != computed_file_length

      (0...record_count).to_a.each do |i|
        contents << process_vld_record(raw_file[i*VLD_RECORD_LENGTH, VLD_RECORD_LENGTH], chapman_code)
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
    # W   T 181  3 Transcriber County code (3a capitals, no default but UNK if not known)
    # X   U 184 20 Transcriber Birth place (default -)
    # Y   V 204  1 Flag for birth place (x or -)
    # Z   W 205  6 Disability (default blank)
    # AA  X 211  1 Language (W, E, B, G or blank)
    # AB  Y 212 44 Notes (default blank, no case
    #     Z 276  3 Alternate birth county
    #     AA 279 20 Alternate birth place

    VLD_POSITION_MAP =
    {
      :deleted_flag => [0,1],
      :hh => [5,6],
      :suffix => [1,4],
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

    def process_vld_record(line, chapman_code = nil)
      record = parse_vld_record(line)
      record = clean_vld_record(record, chapman_code)

      record
    end

    def parse_vld_record(line)
      record = {}
      VLD_POSITION_MAP.each_pair do |attribute, location|
        record[attribute] = line[location[0],location[1]]
      end
      p line if  record[:suffix].length < 4 || !/\A\d+\z/.match(record[:hh]) || !/\A\d+\s+\z/.match(record[:fo_n]) || !/\A\d+\z/.match(record[:seq_in_household])
      p record if  record[:suffix].length < 4 || !/\A\d+\z/.match(record[:hh]) || !/\A\d+\s+\z/.match(record[:fo_n]) || !/\A\d+\z/.match(record[:seq_in_household])
      p 'suffix short' if record[:suffix].length < 4
      p 'household not numeric' if !/\A\d+\z/.match(record[:hh])
      p 'Folio number not numeric ' if !/\A\d+\s+\z/.match(record[:fo_n])
      p 'seuence ont numeric ' if !/\A\d+\z/.match(record[:seq_in_household])
      crash if record[:suffix].length < 4 || !/\A\d+\z/.match(record[:hh]) || !/\A\d+\s+\z/.match(record[:fo_n]) || !/\A\d+\z/.match(record[:seq_in_household])
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
