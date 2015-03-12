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
      process_vld_record(raw_file[i*VLD_RECORD_LENGTH, VLD_RECORD_LENGTH])
    end
  end

  VLD_POSITION_MAP = 
  {
    :deleted_flag => [0,1],
    :hh => [5,6],
    :suffix => [1,3],
    :hu0 => [15,20],
    :hu1 => [35,3],
    :hu2 => [38,1],
    :hu3 => [48,3],
    :hu4 => [51,1],
    :hu5 => [52,4],
    :hu6 => [56,1],
    :hu7 => [57,30],
    :hu8 => [87,1],
    :hu9 => [256,20],
    :individual_flag => [87,1],
    :iu00 => [11,4],
    :iu01 => [88,24],
    :iu02 => [112,24],
    :iu03 => [136,1],
    :iu04 => [137,6],
    :iu05 => [143,1],
    :iu06 => [144,1],
    :iu07 => [145,3],
    :iu08 => [148,1],
    :iu09 => [149,1],
    :iu10 => [150,30],
    :iu11 => [180,1],
    :iu12 => [181,3],
    :iu13 => [184,20],
    :iu14 => [204,1],
    :iu15 => [205,6],
    :iu16 => [211,1],
    :iu17 => [212,44],
    :iu18 => [276,3],
    :iu19 => [279,20],
    :iu20 => [39,4],
    :iu21 => [43,1],
    :iu22 => [44,4],
    :iu23 => [88,24], # original has soundex of iu1'
    :uu0 => [212,44],
    :uu1 => [39,4],
    :uu2 => [43,1],
    :uu3 => [44,4]
  }
  

  
  def process_vld_record(line)
    record = {}
    VLD_POSITION_MAP.each_pair do |attribute, location|
      record[attribute] = line[location[0],location[1]]
    end
    
    record
  end
end

