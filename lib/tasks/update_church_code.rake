namespace :update_church do
  desc "Update church code"
  task church_code: :environment do
    file_path = ENV['FILE_PATH']
    if file_path.nil?
      puts "provide the file path"
      exit
    end

    CsvImportService.new(file_path).csv_import_and_update_church
    puts "Church Codes updated"
  end
end