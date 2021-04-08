task :test_freecen1_vld, [:filename] => [:environment] do |t, args|
  require 'freecen1_vld_parser'
  require 'freecen1_vld_transformer'
  require 'freecen1_vld_translator'

  p 'start'
  process_file(args.filename)
  p 'finished'
end

# see http://west-penwith.org.uk/fctools/doc/reference.html
def process_file(filename)
  print "Processing #{filename}\n"
  parser = Freecen::Freecen1VldParser.new
  file_record, num_entries = parser.process_vld_file(filename)

  transformer = Freecen::Freecen1VldTransformer.new
  transformer.transform_file_record(file_record)

  translator = Freecen::Freecen1VldTranslator.new
  num_dwel, num_ind = translator.translate_file_record(file_record)
  #print "\t#{filename} contained #{file_record.freecen_dwellings.count} dwellings in #{file_record.freecen1_vld_entries.count} entries\n"
  print "\t#{filename} contained #{num_dwel} dwellings in #{num_entries} entries\n"
  return

end
