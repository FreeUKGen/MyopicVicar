
desc 'clean up production log files'
task :delete_old_txt_and_log_files => [:environment] do |t|
  number = 0
  p "Starting log clean up at #{Time.now}"
  Dir.glob(Rails.root.join('log', '*.txt')).each do |filename|
    File.delete(filename) if File.mtime(filename) < 60.days.ago
    number += 1
  end
  Dir.glob(Rails.root.join('log', '*.log')).each do |filename|
    File.delete(filename) if File.mtime(filename) < 60.days.ago
    p filename
    number += 1
  end

  p "finished with #{number} deleted"
end
