task :update_civil_parish_information, [:limit, :file] => [:environment] do |t, args|
  require 'update_civil_parish_information'
  UpdateCivilParishInformation.process(args.limit, args.file)
end
