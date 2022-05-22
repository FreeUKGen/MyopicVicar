namespace :freecen do
  desc 'Set Freecen2 Place Source (with url specified) to dropdown value'
  task :set_fc2_place_source_to_dropdown_value, [:old_value, :new_value] => [:environment] do |task, args|
    start_time = Time.now
    puts args
    old_value_arg = args.old_value.to_s
    new_value_arg = args.new_value.to_s
    p 'Started Set Freecen2 Place Source (with url specified) to dropdown value'
    if old_value_arg.blank? || new_value_arg.blank?
      puts 'ERROR: Old value (not case sensitive) and New value (must match valid Freecen2_place_sources value) must be provided as arguments'
    elsif !Freecen2PlaceSource.where(source: new_value_arg).count.positive?
      puts "ERROR: New Value #{new_value_arg} - does not exist in freecen2_place_sources"
    else
      old_value = old_value_arg.downcase
      recs_to_update_count = 0
      fc2_places = Freecen2Place.where(disabled: 'false')
      fc2_places.each do |rec|
        recs_to_update_count += 1 if rec.source.present? && rec.genuki_url.present? && rec.source.downcase.rstrip == old_value
      end
      if !recs_to_update_count.positive?
        puts 'No freecen2_place records found to update'
      else
        puts "Found #{recs_to_update_count} Freecen2Place records to update"
        recs_updated_count = 0
        Freecen2Place.where(disabled: 'false').no_timeout.each do |place|
          if place.source.present? && place.genuki_url.present? && place.source.downcase.rstrip == old_value
            place.set(source: new_value_arg)
            recs_updated_count += 1
            p "#{recs_updated_count} records updated" if (recs_updated_count % 100).zero?
          end
        end
        running_time = Time.now - start_time
        p "Finished Set Freecen2 Place Source (with url specified) to dropdown value - #{recs_updated_count} records updated in #{running_time} secs"
      end
    end
  end
end
