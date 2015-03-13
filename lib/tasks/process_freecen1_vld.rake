namespace :freecen do

  desc "Process legacy FreeCEN1 VLD files"
  task :process_freecen1_vld, [:filename] => [:environment] do |t, args| 
    process_vld_file(args.filename)

  end

  # TODO move to library
  
  def process_vld_file(filename)
    process_vld_filename
    process_vld_contents(filename)
  end


  def process_vld_filename
    
  end
  
  VLD_RECORD_LENGTH = 299
  
  def process_vld_contents(filename)
    # open the file
    raw_file = File.read(filename)
    # loop through each 299-byte substring
    record_count = raw_file.length / VLD_RECORD_LENGTH
    (0...record_count).to_a.each do |i|
      pp process_vld_record(raw_file[i*VLD_RECORD_LENGTH, VLD_RECORD_LENGTH])[:suffix]
    end
  end

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
    :unoccupied_fo_n => [39,4],
    :unoccupied_fo_a => [43,1],
    :unoccupied_pg_n => [44,4]
  }
  

  
  def process_vld_record(line)
    record = parse_vld_record(line)
    record = clean_vld_record(record)
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
    record = raw_record.map do |attr|
       [attr[0], attr[1].sub(/\s*$/, '')]
    end
    
    
 
  end
end

