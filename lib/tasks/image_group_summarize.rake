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

    image_server_group_id.each do |group_id|
      image_server_image = ImageServerImage.where(:image_server_group_id=>group_id)

      group_status = image_server_image.pluck(:status).compact.uniq
      group_difficulty = image_server_image.pluck(:difficulty).compact.uniq
      group_transcriber = image_server_image.pluck(:transcriber).flatten.compact.uniq
      group_reviewer = image_server_image.pluck(:reviewer).flatten.compact.uniq
      group_count = image_server_image.count()

      if ImageServerGroup.where(:id=>group_id).update_all(:status=>group_status, :difficulty=>group_difficulty, :transcriber=>group_transcriber, :reviewer=>group_reviewer, :number_of_images=>group_count)
        p "ImageServerGroup "+group_id.to_s+", status="+group_status.to_s+", difficulty="+group_difficulty.to_s+", transcriber="+group_transcriber.to_s+", reviewer="+group_reviewer.to_s+", count="+group_count.to_s
      else
        p "FAILURE to summarize ImageServerGroup "+group_id.to_s+"with values status="+group_status.to_s+", difficulty="+group_difficulty.to_s+", transcriber="+group_granscriber.to_s+", reviewer="+group_reviewer.to_s+", count="+group_count.tos
        error_file.puts "FAILURE to summarize ImageServerGroup "+group_id.to_s+"with values status="+group_status.to_s+", difficulty="+group_difficulty.to_s+", transcriber="+group_granscriber.to_s+", reviewer="+group_reviewer.to_s+", count="+group_count.to_s
      end
    end
    error_file.close
  end

end
