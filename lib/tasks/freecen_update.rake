
# this gets called by /lib/tasks/scripts/update_freecen2_production.sh
# values would normally be:
#   parms_dir:   /raid/freecen2/freecen1/fixed
#   vld_dir:     /raid/freecen2/freecen1/pieces
task :freecen_update_from_FC1,[:parms_dir,:vld_dir] => [:environment] do |t,args|
  p "-----------------------------------------------------------"
  p ">>>freecen_update.rake freecen_update_from_FC1 task start"

  require 'freecen1_update_processor'

  Freecen1UpdateProcessor.update_all(args[:parms_dir],args[:vld_dir])
  p ">>>freecen_update.rake freecen_update_from_FC1 task finished"
end

