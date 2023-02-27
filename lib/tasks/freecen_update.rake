# this gets called by /lib/tasks/scripts/update_freecen2_production.sh
# values would normally be:
#   parms_dir:   /raid/freecen2/freecen1/fixed
#   vld_dir:     /raid/freecen2/freecen1/pieces
task :freecen_update_from_FC1,[:parms_dir,:vld_dir] => [:environment] do |t,args|
  p '-----------------------------------------------------------'
  p 'freecen_update.rake freecen_update_from_FC1 task start'

  require 'freecen1_update_processor'

  Freecen1UpdateProcessor.update_all(args[:parms_dir],args[:vld_dir])
  p 'Documenting the Update...'
  FreecenUtility.document_db_update
  p 'freecen_update.rake freecen_update_from_FC1 task finished'

end

# the vld_basename is case-sensitive and does not include the full path,
# for example: rg121798.vld or HS411168.VLD
# You can enter a single filename or a comma-separated list.
task :freecen_vld_clear_digest,[:vld_basename] => [:environment] do |t,args|
  require 'freecen1_update_processor'
  Freecen1UpdateProcessor.clear_vld_digest(args[:vld_basename])
  if args.extras.present?
    args.extras.each do |aa|
      Freecen1UpdateProcessor.clear_vld_digest(aa)
    end
  end
end
# the vld_basename is case-sensitive and does not include the full path,
# for example: rg121798.vld or HS411168.VLD
# You can enter a single filename or a comma-separated list.
task :freecen_csv_file_incorporate, [:freecen_csv_file] => [:environment] do |t, args|
  require 'freecen_csv_file_incorporate'
  FreecenCsvFileIncorporate.incorporate(args[:freecen_csv_file])
  p 'Incorporation complete'
end

task :freecen_csv_file_unincorporate, [:freecen_csv_file, :userid] => [:environment] do |t, args|
  require 'freecen_csv_file_unincorporate'
  FreecenCsvFileUnincorporate.unincorporate(args[:freecen_csv_file],args[:userid])
  p 'Record removal complete'
end
