class GetWaitingFileList
  def self.process
    process_file = File.new(Rails.application.config.processing_delta,"w")
    puts " Using #{Rails.application.config.website}"
    files = PhysicalFile.waiting.all
    names = Array.new
    files.each do |file|
      names << "#{file.userid}/#{file.file_name}"
    end
    names.uniq
    names.each do |name|
      process_file.puts name
    end
    process_file.close
  end #end process
end
