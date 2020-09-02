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
  when 4
    correct_place_names_in_census(year)
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
  distinct = Freecen2CivilParish.distinct('place_name')
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
          place_id = place.present? ? place.id : nil
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
def correct_place_names_in_census(year)
  file_for_warning_messages = "#{Rails.root}/log/correct_census_place_names.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  output_file = File.new(file_for_warning_messages, "w")
  p "Correcting #{year} census place names"
  output_file.puts
  record_number = 0
  corrected_records = 0
  Freecen2Piece.distinct(:chapman_code).each do |chapman|
    p "#{chapman}"
    Freecen2District.where(chapman_code: chapman, year: year).all.each do |district|
      district_freecen2_place_id = district.freecen2_place_id
      place_valid, place_id = Freecen2Place.valid_place(chapman, district.name)
      if place_valid && place_id != district_freecen2_place_id
        district.update_attribute(:freecen2_place_id, place_id)
        district_freecen2_place_id = place_id
        corrected_records += 1
      end
      district.freecen2_pieces.each do |piece|
        piece_freecen2_place_id = piece.freecen2_place_id
        place_valid, place_id = Freecen2Place.valid_place(chapman, piece.name)
        if place_valid && place_id != piece_freecen2_place_id
          piece.update_attribute(:freecen2_place_id, place_id)
          corrected_records += 1
          piece_freecen2_place_id = place_id
        elsif !place_valid && district_freecen2_place_id.present? && piece_freecen2_place_id != district_freecen2_place_id
          piece.update_attribute(:freecen2_place_id, district_freecen2_place_id)
          corrected_records += 1
          piece_freecen2_place_id = district_freecen2_place_id
        end
        piece.freecen2_civil_parishes.all.each do |civil_parish|
          civil_parish_freecen2_place_id = civil_parish.freecen2_place_id
          record_number += 1
          place_valid, place_id = Freecen2Place.valid_place(chapman, civil_parish.name)
          if place_valid
            if place_id != civil_parish_freecen2_place_id
              civil_parish.update_attribute(:freecen2_place_id, place_id)
              corrected_records += 1
              civil_parish_freecen2_place_id = place_id
            end
          else
            if piece_freecen2_place_id.present?
              if civil_parish_freecen2_place_id != piece_freecen2_place_id
                civil_parish.update_attribute(:freecen2_place_id, piece_freecen2_place_id)
                corrected_records += 1
                civil_parish_freecen2_place_id = piece_freecen2_place_id
              end
            elsif district_freecen2_place_id.present? && civil_parish_freecen2_place_id != district_freecen2_place_id
              civil_parish.update_attribute(:freecen2_place_id, district_freecen2_place_id)
              corrected_records += 1
              civil_parish_freecen2_place_id = district_freecen2_place_id
            end
          end
        end
      end
    end
  end
  p "processed #{record_number} civil parishes, #{corrected_records} districts, pieces and civil parishes were corrected"
end
