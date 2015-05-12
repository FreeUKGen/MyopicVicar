require 'freecen1_vld_parser'
namespace :freecen do
  # see http://west-penwith.org.uk/fctools/doc/reference.html
  desc "Process legacy FreeCEN1 VLD files"
  task :process_freecen1_vld, [:filename] => [:environment] do |t, args| 
    parser = Freecen::Freecen1VldParser.new
    parser.process_vld_file(args.filename)
  end


end

