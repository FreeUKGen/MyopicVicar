class ListOfErrorFiles

  require "#{Rails.root}/app/models/freereg1_csv_file"
  require "#{Rails.root}/app/models/batch_error"
  include Mongoid::Document

  def self.process(limit)
    file_for_warning_messages = "log/list_error_files.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, "w")
    limit = limit.to_i
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    puts "checking #{limit} batch error for missing linkages"
    files_with_errors = Freereg1CsvFile.gt(error: 0).only(:userid,:file_name,:error).all
    p "#{files_with_errors.count} files with errors"
     error_files = Array.new
    files_with_errors.each do |file|
      error_files << file._id
      errors = BatchError.where(:freereg1_csv_file_id => file._id).all
      error = 0 
      error = errors.count unless errors.nil?
      
      if error == file.error
       puts "#{file.userid},#{file.file_name},#{file.error},#{error},Good"
      else 
       message_file.puts "#{file.userid}/#{file.file_name}"
      end 
    end
    batch_error_count = BatchError.count
    p "#{batch_error_count} batch error records" 
    BatchError.only(:freereg1_csv_file_id).each do  |batch|
      batch_id = batch.freereg1_csv_file_id
      begin
      file = nil
      file = Freereg1CsvFile.find(batch_id)
      rescue Mongoid::Errors::DocumentNotFound
      rescue Mongoid::Errors::InvalidFind
      end
      if file.nil?
        puts "#{batch_id}, does not exist"
        batch.destroy
      else
        ind = error_files.find_index(batch_id)
        error_files.delete_at(ind) unless ind.nil? 
      end
    end 
       p "#{error_files.count} files are missing their records"

  end
end
