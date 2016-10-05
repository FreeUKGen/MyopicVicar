module Freecen
  class Freecen1MetadataDatParser
      
    def process_dat_file(filename)
      file_record = process_dat_filename(filename)
      entry_records = process_dat_contents(filename)
      persist_to_database(filename, file_record, entry_records)
    end
  
    def persist_to_database(filename, file_hash, entry_hash_array)
      dat_entry_num = 1
      file = Freecen1FixedDatFile.new(file_hash)
      file.save!

      entry = nil
      a_entry = nil
      entry_hash_array.each do |hash|
        if hash[:rectype] == 'a'
          # this is a new piece
          #
          # save the old one if needed
          
          entry.save! if entry
          
          # now create a new one
          entry = Freecen1FixedDatEntry.new
          entry.entry_number = dat_entry_num
          dat_entry_num += 1
          entry.freecen1_fixed_dat_file = file
          entry.district_name = hash[:distname]
          entry.subplaces = []
          entry.lds_film_number = hash[:a_lds_film_num]
          if is_scotland? file
            entry.piece_number = hash[:a_sct_piecenum].to_i
            entry.suffix = hash[:a_sct_suffix]
            entry.suffix.strip! unless entry.suffix.nil?
            entry.suffix = nil if entry.suffix.blank?
            
            # $parnum = substr($line,64,1);
            parish_number = hash[:a_sct_parnum]
            # $paroff = 1;
            # $paroff = substr($line,95,1) if (substr($line,93,1) eq "S" && substr($line,96,1) == $parnum);
            if hash[:a_sct_paroff_cond_a] == "S" && hash[:a_sct_paroff_cond_b] == parish_number
              paroff = hash[:a_sct_paroff_a_and_b].to_i
            else
              paroff = 1
            end
            # $parnum = $parnum + ($paroff*10);
            entry.parish_number = (parish_number.to_i + paroff*10)
            #p ">>is_scotland? TRUE, piece_number=#{entry.piece_number} parish_number=#{entry.parish_number} suffix='#{entry.suffix}'"
          else
            entry.piece_number = hash[:a_piecenum].to_i
            entry.parish_number = nil
            entry.suffix = nil
          end
          a_entry = entry
        else
          if is_scotland? file
            # scotland split files do not always follow the a/b record format.
            # For example ABD1861 has an a record followed by several b records
            # that are each for a different file, each of which should be
            # treated as if it has that same a record before it.
            freecen_filename = hash[:b_filename]
            freecen_filename.strip! unless freecen_filename.nil?
            puts "*** sct entry missing freecen_filename #{entry.piece_number}" if freecen_filename.blank?
            suffix = hash[:b_sct_suffix]
            suffix.strip! unless suffix.nil?
            suffix = nil if suffix.blank?
            parish_number = hash[:b_sct_parnum]
            if hash[:b_sct_paroff_cond_a] == "S" && hash[:b_sct_paroff_cond_b] == parish_number
              paroff = hash[:b_sct_paroff_a_and_b].to_i
            else
              paroff = 1
            end
            parish_number = (parish_number.to_i + paroff*10)
            entry.freecen_filename = freecen_filename if entry.freecen_filename.blank? && !freecen_filename.blank?
            if parish_number != a_entry.parish_number
              # a different split file, save the entry and create a new one
              entry.save! if entry 
              entry = Freecen1FixedDatEntry.new
              entry.entry_number = dat_entry_num
              dat_entry_num += 1
              entry.piece_number = a_entry.piece_number
              entry.parish_number = parish_number
              entry.suffix = suffix
              entry.freecen1_fixed_dat_file = file
              entry.district_name = a_entry.district_name
              entry.lds_film_number = a_entry.lds_film_number
              entry.freecen_filename = freecen_filename
              entry.subplaces = []
            end
          end
          # sub place for an existing piece
          entry.subplaces << {'name'=>hash[:distname],'lat'=>0.0,'long'=>0.0}
        end
          
      end
      entry.save! if entry
      
      file
    end
  
    def is_scotland?(file)
      return true if 'SCS'==file.chapman_code
      ChapmanCode::CODES["Scotland"].values.include? file.chapman_code
    end
  
    def process_dat_filename(filepath)
      filename = File.basename(filepath)
      dirname = File.basename(File.dirname(filepath))
      chapman_code = filename[0,3]
      file_digest = Digest::MD5.file(filepath).to_s rescue nil

      { :chapman_code => chapman_code, :year => dirname, :filename => filename, :dirname => dirname, :file_digest => file_digest }
    end
    
    DAT_RECORD_LENGTH = 64
    
    def process_dat_contents(filename)
      # open the file
      raw_file = File.read(filename)
      # loop through each 64-byte substring
      record_count = raw_file.length / DAT_RECORD_LENGTH - 1
      contents = []
      (0...record_count).to_a.each do |i|
        contents << process_dat_record(raw_file[64 + i*DAT_RECORD_LENGTH, DAT_RECORD_LENGTH*2]) #RECORD_LENGTH*2 because several offsets are > 63
      end
      
      contents
    end
    
    # 4 (0-3) : piece No
    # 4 (4-7) : reg dist No
    # 20 (8-27) : reg sub-dist name (for 'a') / civil parish name (for 'b')
    # 8 (28-35): LDS film # or filename
    # 24 (36-59): spaces
    # 3 (60-62): 3 spaces or SCT OPN supp Nos (OPN is Original Parish Number)
    # 1 (63): 'a' or 'b'
    
    DAT_POSITION_MAP = 
    {
      :distname => [8,20],
      :rectype => [63,1],
      :toponym => [8,20],

      :a_piecenum => [0,4],
      
      :a_sct_piecenum => [1,3],
      :a_sct_suffix =>  [124,3],
      :a_sct_parnum => [64,1],
      :a_sct_paroff_cond_a => [93,1],
      :a_sct_paroff_cond_b => [96,1],
      :a_sct_paroff_a_and_b => [95,1],
      :a_lds_film_num => [28,8],
      
      :b_suffix => [60,3],
      :b_sct_suffix => [60,3],
      :b_sct_parnum => [0,1],
      :b_sct_paroff_cond_a => [29,1],
      :b_sct_paroff_cond_b => [32,1],
      :b_sct_paroff_a_and_b => [31,1],
      :b_filename => [28,8]
     
    }
    
  
    
    def process_dat_record(line)
      record = parse_dat_record(line)
      record = clean_dat_record(record)
      
      record
    end

    def print_record(record)
      if record[:rectype] == 'a'
        print "\n"
        print record[:a_piecenum]
        print "\t"
        print record[:toponym]
        print
      else
        print record[:toponym].gsub(/\s+$/, '')
        print " "
      end
    end
    
    def parse_dat_record(line)
      record = {}
      DAT_POSITION_MAP.each_pair do |attribute, location|
        record[attribute] = line[location[0],location[1]]
      end
      # print_record(record)
      
      record
    end
    
    def clean_dat_record(raw_record)
      # trim trailing whitespace
      record = {}
      raw_record.each_pair do |key,value|
        clean_value = value.encode('ISO-8859-15', { :invalid => :replace, :undef => :replace, :replace => ''}).sub(/\s*$/, '') if value
        record[key] = clean_value unless clean_value.blank?       
      end
      
      # # fix schn over 1000
      # if record[:sch_a] == "!"
        # record[:sch_n] = (1000+record[:sch_n].to_i).to_s
      # end
#           
      # [:t_born_cty, :born_cty].each do |key|
        # record[key] = 'WAL' if record[key] == 'WLS'
        # record[key] = 'KCD' if record[key] == 'KIN'
        # record[key] = 'UNK' if record[key] == ''
      # end
#   
      # record[:notes] = '' if record[:notes] =~ /\[see mynotes.txt\]/
    
      # nil out blanks
      
      record
    end
  end
end
