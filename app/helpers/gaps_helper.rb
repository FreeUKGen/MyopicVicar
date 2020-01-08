module GapsHelper
  def freereg1_csv_file_name(x)
    file = Freereg1CsvFile.find_by(_id: x.freereg1_csv_file)
    file_name = file.present? ? file.file_name : ''
  end
end
