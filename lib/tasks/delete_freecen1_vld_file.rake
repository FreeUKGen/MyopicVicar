namespace :freecen do
  desc 'Delete a Freecen1 VLD file and associated database records (background task)'
  task :delete_freecen1_vld_file, [:vld_id, :userid] => [:environment] do |_t, args|
    abort 'vld_id is required' if args[:vld_id].blank?
    abort 'userid is required' if args[:userid].blank?

    require 'freecen1_vld_file_delete'
    Freecen1VldFileDelete.run(args[:vld_id], args[:userid])
  end
end
