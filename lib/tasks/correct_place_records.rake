require 'chapman_code'

task :correct_place_records,[:option] => :environment do |t, args|
  option = args.option.to_i
  case option
  when 1
    duplicate_place_records
  when 2
    distinct_names
  when 3
    standardized_names
  end
end
def duplicate_place_records
  file_for_warning_messages = "#{Rails.root}/log/places_in_gazetter.csv"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
  output_file = File.new(file_for_warning_messages, "w")
  puts "Checking place documents for duplication"
  record_number = 0
  corrected_records = 0

  Freecen2Place.distinct(:chapman_code).each do |ch|
    p "#{ch}"
    Freecen2Place.where(chapman_code: ch).each do |pl|
      record_number += 1
      name = pl.place_name
      places = Freecen2Place.where(chapman_code: ch, place_name: name).all
      p places.count if places.count > 2
      output_file "#{ch},#{name}" if places.count > 2
    end
  end

  puts "checked #{record_number} entries there were #{corrected_records} duplicated places"
  output_file.close
end
def distinct_names
  file_for_warning_messages = "#{Rails.root}/log/places_in_gazetter.csv"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
  output_file = File.new(file_for_warning_messages, "w")
  p "Checking distinct names"
  distinct = Freecen2Place.distinct('place_name')
  output_file.puts distinct
  p 'finished'
end

def standardized_names
  file_for_warning_messages = "#{Rails.root}/log/places_in_gazetter.csv"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
  output_file = File.new(file_for_warning_messages, "w")
  p "Creating standardized names"
  record_number = 0
  corrected_records = 0

  Freecen2Place.distinct(:chapman_code).each do |ch|
    p "#{ch}"
    Freecen2Place.where(chapman_code: ch).each do |pl|
      record_number += 1

      pl.standard_place_name = Freecen2Place.standard_place(pl.place_name)
      pl.original_standard_name = Freecen2Place.standard_place(pl.original_place_name) if pl.original_place_name.present?
      pl.alternate_freecen2_place_names.each do |alt|
        alt.standard_alternate_name = Freecen2Place.standard_place(alt.alternate_name)
      end
      pl.save
      output_file.puts pl.inspect
    end
  end
  p "processed #{record_number} places"
end
