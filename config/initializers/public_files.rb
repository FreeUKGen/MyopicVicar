# The three sites (freereg / freecen / freebmd) have front-end public files that
# are site-specific, but have the same file names for each site.
# Any files in the public_site_specific/freebmd, freecen and freereg folders are copied into the
# public folder for the application at initialization. All previous files are first removed

require 'fileutils'

freexxx = MyopicVicar::Application.config.template_set
st_src_dir = Rails.root.join('public_site_specific', '#{freexxx}').to_s
cmn_src_dir = Rails.root.join('public_site_specific', 'common_files').to_s
@st_dst_dir = Rails.root.join('public').to_s
public_system_dir = Rails.root.join('public', 'system').to_s

new_static_files = Dir.glob(File.join(st_src_dir, '*').to_s)
old_static_files = Dir.glob(File.join(@st_dst_dir, '*').to_s)
new_common_files = Dir.glob(File.join(cmn_src_dir, '*').to_s)

old_static_files.each do |f|
  FileUtils.rm_f(f)
end

Dir.mkdir(public_system_dir) unless Dir.exist?(public_system_dir)

def refresh_public file_folder
  file_folder.each do |f|
    FileUtils.cp_r(f, @st_dst_dir)
  end
end

refresh_public new_static_files
refresh_public new_common_files
