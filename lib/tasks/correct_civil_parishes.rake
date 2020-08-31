require 'chapman_code'

task :correct_civil_parishes,[:option, :year] => :environment do |t, args|
  option = args.option.to_i
  year = args.year.to_s

  case option
  when 1
    duplicated_civil_parishes
  when 2
    distinct_civil_parishes
  when 3
    correct_census(year)
  end
end
def duplicated_civil_parishes
  file_for_warning_messages = "#{Rails.root}/log/duplicated_civil_parishes.log"
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
def distinct_civil_parishes
  file_for_warning_messages = "#{Rails.root}/log/distict_civil_parishes.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
  output_file = File.new(file_for_warning_messages, "w")
  p "Checking distinct names"
  distinct = Freecen2Place.distinct('place_name')
  output_file.puts distinct
  p 'finished'
end

def correct_census(year)
  file_for_warning_messages = "#{Rails.root}/log/correct_census_civil_parishes.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
  output_file = File.new(file_for_warning_messages, "w")
  p "Correcting #{year }civil parishes"
  output_file.puts
  record_number = 0
  corrected_records = 0
  Freecen2Piece.distinct(:chapman_code).each do |chapman|
    p "#{chapman}"
    Freecen2Piece.where(chapman_code: chapman, year: year).each do |piece|
      record_number += 1
      piece_id = piece.id
      piece.freecen2_civil_parishes.all.each do |civil_parish|
        civil_parish.freecen2_hamlets.all.each do |hamlet|
          corrected_records += 1
          place_valid, place_id = Freecen2Place.valid_place(chapman, hamlet.name)
          if !place_valid
            place_id = piece.freecen2_place
            if place_id.blank?
              district_id = piece.freecen2_district
              place_id = district_id.freecen2_place
            end
          end
          place = Freecen2Place.find_by(_id: place_id) if place_id.present?
          output_file.puts " #{place.place_name},  #{piece.name}, #{civil_parish.name}, #{hamlet.name} " if place_id.present?
          output_file.puts " No place ,  #{piece.name}, #{civil_parish.name}, #{hamlet.name} " if place_id.blank?
          new_civil_parish = Freecen2CivilParish.new(name: hamlet.name, note: hamlet.note, freecen2_piece_id: piece_id, prenote: hamlet.prenote,
                                                     freecen2_place_id: place_id, year: year, chapman_code: chapman)
          result = new_civil_parish.save
          if result
            civil_parish.freecen2_hamlets.delete(hamlet)
          else
            p 'save failed'
            crash
          end
        end
      end
      civil_parish_names = piece.add_update_civil_parish_list
      piece.update(civil_parish_names: civil_parish_names) unless civil_parish_names == piece.civil_parish_names
    end
  end
  p "processed #{record_number} pieces, #{corrected_records} were converted"
end
