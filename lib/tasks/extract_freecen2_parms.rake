task :extract_freecen2_parms, [:limit, :file] => [:environment] do |t, args|
  require 'extract_freecen2_piece_information'
  ExtractFreecen2PieceInformation.process(args.limit, args.file)
end
