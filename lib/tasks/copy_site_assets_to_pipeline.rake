# The three sites (freereg / freecen / freebmd) have front-end assets that
# are site-specific, but have the same file names for each site.
# Due to the way the asset pipeline works we cannot include all 3 sets of
# assets in the app/assets directory.  Instead, we have created 
# app/assets_free[reg/cen/bmd] directories outside of the normal app/assets
# directory, and must copy the correct assets from there into app/assets
#
# This rake task copies the correct site-specific assets
# from app/assets_freeXXX
# into app/assets/copy_of_assets_freeXXX
# (after deleting any existing app/assets/copy_of_assets_free* directories)
#
# Any changes to the site-specific assets need to happen in:
# app/assets_freereg, app/assets_freecen, or app/assets_freebmd
# because the directory copied into app/assets is replaced whenever this task
# is run, and the copied directory is also ignored by git.

require 'fileutils'

desc "copy_site_assets_to_pipeline"
task :copy_site_assets_to_pipeline => :environment do
  remove_freexxx_site_assets
  copy_freexxx_site_assets
end

def remove_freexxx_site_assets
  fRemoved=false
  ['freereg', 'freecen', 'freebmd'].each do |freexxx|
    stDir = Rails.root.join('app','assets',"copy_of_assets_#{freexxx}").to_s
    if Dir.exists?(stDir)
      puts "removing previous copy of site-specific assets:\n  #{stDir}"	
      FileUtils.rm_rf(stDir)
      fRemoved=true
    end
  end
  if !fRemoved
    puts "no previous copy of site-specific assets to be removed from app/assets"
  end
end

def copy_freexxx_site_assets
  freexxx=MyopicVicar::Application.config.template_set
  stSrcDir = Rails.root.join('app',"assets_#{freexxx}").to_s
  stDstDir = Rails.root.join('app','assets',"copy_of_assets_#{freexxx}").to_s
  rgFilesToCopy=Dir.glob(File.join(stSrcDir,"*").to_s)
  rgFilesToCopy.each do |f|
    puts "copying site specific assets\n  from " + f + "/*\n  to #{stDstDir}/"
    FileUtils.cp_r(File.join(f,"."),stDstDir)
  end
end
