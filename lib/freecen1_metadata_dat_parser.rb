module Freecen
  class Freecen1MetadataDatParser
      
    def process_dat_file(filename)
      file_record = process_dat_filename(filename)
      entry_records = process_dat_contents(filename)
      persist_to_database(filename, file_record, entry_records)
    end
  
    def persist_to_database(filename, file_hash, entry_hash_array)
      file = Freecen1FixedDatFile.new(file_hash)
      file.save!

      entry = nil
      entry_hash_array.each do |hash|
        if hash[:rectype] == 'a'
          # this is a new piece
          #
          # save the old one if needed
          entry.save! if entry 
          
          # now create a new one
          entry = Freecen1FixedDatEntry.new        
          entry.freecen1_fixed_dat_file = file
          entry.district_name = hash[:distname]
          entry.subplaces = []
          if is_scotland? file
            entry.piece_number = hash[:a_sct_piecenum].to_i
            entry.suffix = hash[:a_sct_suffix]            
            
            # $parnum = substr($line,64,1);
            parish_number = hash[:a_sct_parnum].to_i
            # $paroff = 1;
            # $paroff = substr($line,95,1) if (substr($line,93,1) eq "S" && substr($line,96,1) == $parnum);
            if hash[:a_sct_paroff_cond_a] == "S" && hash[:a_sct_paroff_cond_b] == entry.parish_number
              paroff = hash[:a_paroff_a_and_b].to_i
            else
              paroff = 1            
            end
            # $parnum = $parnum + ($paroff*10);
            entry.parish_number = (parish_number + paroff*10).to_s
          else
            entry.piece_number = hash[:a_piecenum].to_i
            entry.parish_number = '0'
            entry.suffix = ''
          end
        else
          # sub place for an existing piece
          entry.subplaces << hash[:distname]
        end
      end
      entry.save! if entry
      
      file
    end
  
    def is_scotland?(file)
      ChapmanCode::CODES["Scotland"].values.include? file.chapman_code
    end
  
    def process_dat_filename(filepath)
      filename = File.basename(filepath)
      dirname = File.basename(File.dirname(filepath))
      chapman_code = filename[0,3]

      { :chapman_code => chapman_code, :year => dirname, :filename => filename, :dirname => dirname }
    end
    
    DAT_RECORD_LENGTH = 64
    
    def process_dat_contents(filename)
      # open the file
      raw_file = File.read(filename)
      # loop through each 64-byte substring
      record_count = raw_file.length / DAT_RECORD_LENGTH - 1
      contents = []
      (0...record_count).to_a.each do |i|
        contents << process_dat_record(raw_file[64 + i*DAT_RECORD_LENGTH, DAT_RECORD_LENGTH])
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
      :a_paroff_a_and_b => [95,1],
      
      :b_suffix => [60,3],
      :b_sct_suffix => [60,3],
      :b_sct_parnum => [0,1],
      :b_sct_paroff_cond_a => [29,1],
      :b_sct_paroff_cond_b => [32,1],
      :b_sct_paroff_a_and_b => [31,1],
      
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
