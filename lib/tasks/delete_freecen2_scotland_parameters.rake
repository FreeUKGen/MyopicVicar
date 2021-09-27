task :delete_freecen2_parms_scotland, [:limit] => :environment do |t, args|

  require 'chapman_code'

  file_for_output = "#{Rails.root}/log/scotland_parms.txt"
  FileUtils.mkdir_p(File.dirname(file_for_output) )
  output_file = File.new(file_for_output, "w")


  # Print the time before start the process
  start_time = Time.now
  p "Delete Scottish parms starting at #{start_time}"
  lim = args.limit.to_i
  number = 0

  codes = ChapmanCode.remove_codes(ChapmanCode::CODES)
  codes = codes["Scotland"].values
  codes.each do |chapman|
    p chapman
    Freecen2CivilParish.delete_all(chapman_code: chapman)
    Freecen2Piece.delete_all(chapman_code: chapman)
    Freecen2District.delete_all(chapman_code: chapman)
  end


  p "Process finished"

  running_time = Time.now - start_time
  p "Running time #{running_time}  for #{number - 1} pieces"
end
