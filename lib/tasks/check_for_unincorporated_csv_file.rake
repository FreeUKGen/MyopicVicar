desc "Look for unique Freecen unincorporated files"
require 'chapman_code'

task :check_for_unincorporated_csv_file, [:limit] => :environment do |t, args|
  file_count = 0
  p 'starting csv'
  files = FreecenCsvFile.where(incorporated: false).order_by(updated_at: 1)
  unique_names = files.distinct('file_name')
  p unique_names.length
  unique_names.each do |name|
    report = true
    FreecenCsvFile.where(file_name: name).order_by(updated_at: 1).each do |file|
      report = false if  file.incorporated
    end
    next unless report

    number = 0
    FreecenCsvFile.where(file_name: name).order_by(updated_at: 1).each do |file|
      number += 1
      p "#{name}, #{FreecenCsvFile.where(file_name: name).count}, #{number}, #{file.chapman_code},#{file.userid},#{file.created_at} ,#{file.updated_at}, #{file.validation},#{file.total_records},#{file.completes_piece}"
    end
  end
end
