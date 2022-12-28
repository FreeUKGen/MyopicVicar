namespace :freecen do
  desc 'List sample of Search Records for specified Chapman Code and Place'
  task :list_random_search_records_for_place, [:chapman_code, :place_name, :sample_size] => [:environment] do |t, args|

    chapman_code = args.chapman_code
    place_name = args.place_name
    size_text = args.sample_size
    arg_error = false

    if args.chapman_code.nil? || args.place_name.nil? || args.sample_size.nil?
      arg_error = true
      puts 'ERROR! Please provide all 3 parameters - chapman_code, place_name and sample_size.'
    else
      sample_size = size_text.to_i
      if sample_size > 500 || sample_size < 1
        arg_error = true
        puts "ERROR! sample size #{sample_size} must be between 1 and 500"
      else
        fc2_place_ids = Freecen2Place.where(chapman_code: chapman_code, place_name: place_name).pluck(:id)

        if fc2_place_ids.empty?
          arg_error = true
          puts "ERROR! place #{place_name} not found in #{chapman_code} (check case as matches on place_name field)"
        end
      end
    end

    unless arg_error

      output_file_name = 'log/search_records_sample.csv'

      FileUtils.mkdir_p(File.dirname(output_file_name)) unless File.exist?(output_file_name)
      outfile = File.new(output_file_name, 'w')

      p "Started listing of #{sample_size} random Search records for #{place_name} in #{chapman_code}"

      total = SearchRecord.where({:chapman_code => chapman_code, :freecen2_place_id => { '$in' => fc2_place_ids } }).count

      p "Total Search recs for #{place_name} in #{chapman_code} = #{total}"
      selected_recs = 0

      unless total < 1

        sample_size = total if total < sample_size

        outfile.puts 'Chapman_code,Place_name,District,Piece_number,Civil_Parish,Folio,Page,Schedule,Name'

        for a in 1..sample_size do

            random = rand(1..total)
            results = SearchRecord.where({:chapman_code => chapman_code, :freecen2_place_id => { '$in' => fc2_place_ids } }).skip(random).limit(1)

            results.each do |rec|

              result_rec = SearchRecord.find_by(_id: rec._id)

              # Search record from CSV data
              if result_rec.freecen_csv_entry_id.present?
                csv_entry = FreecenCsvEntry.find_by(_id: result_rec.freecen_csv_entry_id)
                if csv_entry.present?
                  civil_parish = csv_entry.civil_parish
                  folio_number = csv_entry.folio_number
                  page_number = csv_entry.page_number
                  schedule_number = csv_entry.schedule_number
                  surname = csv_entry.surname
                  full_name = "#{forenames} #{surname}"
                else
                  civil_parish = '**MISSING**'
                end
                district = Freecen2District.find_by(_id: result_rec.freecen2_district_id)
                district_name = district.name if district.present?
                if result_rec.freecen2_piece_id.present?
                  piece = Freecen2Piece.find_by(_id: result_rec.freecen2_piece_id)
                  piece_number = piece.number if piece.present?
                end
              end
              # Search record from VLD data
              if result_rec.freecen1_vld_file_id.present?
                vld_file = Freecen1VldFile.find_by(_id: result_rec.freecen1_vld_file_id)
                if vld_file.present?
                  if vld_file.freecen2_district_id.present?
                    district = Freecen2District.find_by(_id: vld_file.freecen2_district_id)
                    district_name = district.name if district.present?
                  end
                  if vld_file.freecen2_piece_id.present?
                    piece = Freecen2Piece.find_by(_id: vld_file.freecen2_piece_id)
                    piece_number = piece.number if piece.present?
                  end
                end
              end
              if result_rec.freecen_individual_id.present?
                individual = FreecenIndividual.find_by(_id: result_rec.freecen_individual_id)
                if individual.present?
                  if individual.freecen1_vld_entry_id.present?
                    vld_entry = Freecen1VldEntry.find_by(_id: individual.freecen1_vld_entry_id)
                    if vld_entry.present?
                      civil_parish = vld_entry.civil_parish
                      folio_number = vld_entry.folio_number
                      page_number = vld_entry.page_number
                      schedule_number = vld_entry.schedule_number
                      surname = vld_entry.surname
                      forenames = vld_entry.forenames
                      full_name = "#{forenames} #{surname}"
                    end
                  end
                end
              end
              outfile.puts "#{chapman_code},#{place_name},#{district_name},#{piece_number},#{civil_parish},#{folio_number},#{page_number},#{schedule_number},#{full_name}"

              selected_recs += 1

            end
          end

          p "#{selected_recs} records selected"

          p "Finished - see #{output_file_name} for output"
        end

      end
    end
  end
