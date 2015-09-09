class CorrectWitnessRecords
  require 'get_files'
  def self.process(len,range)
    #The purpose of this clean up utility is to eliminate blank witness and duplicate witness entries in the database
    #to enable volume control we use the filenames as a means of selection
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    file_for_warning_messages = "log/correct_witness_records.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, "w")
    limit = len.to_i
    message_file.puts "Correcting #{limit} witness record"
    p "Processing batches for #{range}"
    process_batch = 0
    num_witness = 0
    base_directory = Rails.application.config.datafiles
    filenames = GetFiles.get_all_of_the_filenames(base_directory,range)
    p "There are #{filenames.length} files"     
    filenames.each do |filename|
      standalone_filename = File.basename(filename) 
      parent_dirname = File.dirname(File.dirname(filename))
      userid = File.dirname(filename).sub(parent_dirname, '').gsub(File::SEPARATOR, '')
      Freereg1CsvFile.where(userid: userid, file_name: standalone_filename, record_type: 'ma').all.each do |file|
        num_witness = 0
        message_file.puts " #{file.userid} #{file.file_name}"
        p " #{file.userid} #{file.file_name}"
        process_batch = process_batch + 1
        break if process_batch == limit
        file.freereg1_csv_entries.each do |entry|
          witnesses = Array.new
          ind = 0
          multiple_witness = Array.new
          multiple_witness = entry.multiple_witnesses.all
          multiple_witness.each do |witness|
            if  witness.witness_forename.present? || witness.witness_surname.present?
              witness.witness_forename = 'blankfiller' if  witness.witness_forename.blank?
              witnesses[ind] = witness.witness_forename + " " + witness.witness_surname
              entry.multiple_witnesses.delete(witness)
              ind = ind + 1
            else
              #need to get rid of blank entry
              entry.multiple_witnesses.delete(witness)
            end
          end
          if witnesses.present?
            witnesses = witnesses.uniq
            witnesses.each do |witness|
              num_witness =  num_witness + 1
              witness_components = witness.split(" ")
              witness_components[0] = '' if witness_components[0] == 'blankfiller'
              witness_components[1] = '' if witness_components[1] == 'blankfiller'
              my_entry = MultipleWitness.new(:witness_forename => witness_components[0], :witness_surname => witness_components[1])
              entry.multiple_witnesses << my_entry
            end
          end
          entry.save
        end
        message_file.puts "Processed #{file.userid} #{file.file_name} with #{num_witness} witnesses"
        p "Processed #{file.userid} #{file.file_name} with #{num_witness} witnesses"
      end
    end
    message_file.puts "Processed #{process_batch} batches" 
    p  "Processed #{process_batch} batches" 
  end
end
