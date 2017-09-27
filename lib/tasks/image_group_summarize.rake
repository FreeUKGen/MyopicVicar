namespace :image_group_summarize do
  desc "summarize ImageServerImage status/difficulty/transcriber/reviewer into ImageServerGroup."

  task :summarize, [:county] => [:environment] do |t, args|
    file_for_error = "#{Rails.root}/log/summarize_images_error.log"
    FileUtils.mkdir_p(File.dirname(file_for_error))
    error_file = File.new(file_for_error, "w")

    group = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

    place = Place.where(:chapman_code=>args.county).pluck(:id, :chapman_code, :place_name)
    place_id = place.map {|arr| arr[0]}

    church = Church.where(:place_id.in=>place_id).pluck(:id, :place_id, :church_name)
    church_id = church.map {|arr| arr[0]}

    register = Register.where(:church_id.in=>church_id).pluck(:id, :church_id, :register_type)
    register_id = register.map {|arr| arr[0]}

    source = Source.where(:register_id.in=>register_id).pluck(:id, :register_id, :source_name)
    source_id = source.map {|arr| arr[0]}

    image_server_group = ImageServerGroup.where(:source_id.in=>source_id).pluck(:id, :source_id, :group_name)
    image_server_group_id = image_server_group.map {|arr| arr[0]}
      
    place.each do |p1|
      church.each do |c1|
        register.each do |r1|
          source.each do |s1|
            image_server_group.each do |g1|
              x = g1[0].to_s
              group[x] = [p1[2].to_s, c1[2].to_s, r1[2].to_s, s1[2].to_s, g1[2].to_s]
            end
          end
        end
      end
    end

    image_server_group_id.each do |group_id|
      image_server_image = ImageServerImage.where(:image_server_group_id=>group_id)

      group_status = image_server_image.pluck(:status).compact.uniq
      group_difficulty = image_server_image.pluck(:difficulty).compact.uniq
      group_transcriber = image_server_image.pluck(:transcriber).flatten.compact.uniq
      group_reviewer = image_server_image.pluck(:reviewer).flatten.compact.uniq
      group_count = image_server_image.count()

      if ImageServerGroup.where(:id=>group_id).update_all(:status=>group_status, :difficulty=>group_difficulty, :transcriber=>group_transcriber, :reviewer=>group_reviewer, :number_of_images=>group_count)
        p "place="+group[group_id.to_s][0].to_s+", church="+group[group_id.to_s][1].to_s+", register="+group[group_id.to_s][2].to_s+", source="+group[group_id.to_s][3].to_s+", group="+group[group_id.to_s][4].to_s+", status="+group_status.join('::')+", difficulty="+group_difficulty.join('::')+", transcriber="+group_transcriber.join('::')+", reviewer="+group_reviewer.join('::')+", count="+group_count.to_s
      else
        p "FAILURE: place="+group[group_id.to_s][0].to_s+", church="+group[group_id.to_s][1].to_s+", register="+group[group_id.to_s][2].to_s+", source="+group[group_id.to_s][3].to_s+", group="+group[group_id.to_s][4].to_s+", status="+group_status.join('::')+", difficulty="+group_difficulty.join('::')+", transcriber="+group_transcriber.join('::')+", reviewer="+group_reviewer.join('::')+", count="+group_count.to_s
        error_file.puts "FAILURE: place="+group[group_id.to_s][0].to_s+", church="+group[group_id.to_s][1].to_s+", register="+group[group_id.to_s][2].to_s+", source="+group[group_id.to_s][3].to_s+", group="+group[group_id.to_s][4].to_s+", status="+group_status.join('::')+", difficulty="+group_difficulty.join('::')+", transcriber="+group_transcriber.join('::')+", reviewer="+group_reviewer.join('::')+", count="+group_count.to_s
      end
    end
    error_file.close
  end

end
