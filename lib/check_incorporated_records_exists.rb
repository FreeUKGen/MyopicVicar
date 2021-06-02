class CheckIncorporatedRecordsExists

  def self.process
    file_for_output = "#{Rails.root}/log/incorporated_records.txt"
    FileUtils.mkdir_p(File.dirname(file_for_output) )
    output_file = File.new(file_for_output, "w")
    selection = FreecenCsvFile.where(incorporated: true)
    files = selection.count
    p "There are  #{files} files"
    selection.each do |file|
      records = SearchRecord.where(freecen_csv_file_id: file.id).count
      p " #{file.id}, #{file.chapman_code}, #{file.file_name}, #{records}"
    end
    output_file.close
  end
end
