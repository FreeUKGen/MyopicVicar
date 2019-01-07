class CheckImageAvailability

  def self.process(limit)
    #The purpose of this clean up utility is to eliminate search records that are unconnected with an entry. Or an entry without a batch
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")

    file_for_warning_messages = "log/check_image_availability.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
    message_file = File.new(file_for_warning_messages, "w")

    p "#{limit}"
    records = 0
    orphans = 0
    time_start = Time.now
    source_name = ''
    register_name = ''
    church_name = ''
    grand_total = { "u" => 0, "ar" => 0, "a" => 0, "ts" => 0, "t" => 0, "br" => 0, "rs" => 0, "r" => 0, "cs" => 0, "c" => 0, "blank" => 0}
    County.each do |county|
      chapman = county.chapman_code
      county_total = { "u" => 0, "ar" => 0, "a" => 0, "ts" => 0, "t" => 0, "br" => 0, "rs" => 0, "r" => 0, "cs" => 0, "c" => 0, "blank" => 0}
      Place.chapman_code(chapman).each do |place|
        place_name = place.place_name
        place_total = { "u" => 0, "ar" => 0, "a" => 0, "ts" => 0, "t" => 0, "br" => 0, "rs" => 0, "r" => 0, "cs" => 0, "c" => 0, "blank" => 0}
        place.churches.each do |church|
          church_name = church.church_name
          church_total = { "u" => 0, "ar" => 0, "a" => 0, "ts" => 0, "t" => 0, "br" => 0, "rs" => 0, "r" => 0, "cs" => 0, "c" => 0, "blank" => 0}
          church.registers.each do |register|
            register_name = register.register_name
            register_total = { "u" => 0, "ar" => 0, "a" => 0, "ts" => 0, "t" => 0, "br" => 0, "rs" => 0, "r" => 0, "cs" => 0, "c" => 0, "blank" => 0}
            register.sources.each do |source|
              source_name = source.source_name
              source_total = { "u" => 0, "ar" => 0, "a" => 0, "ts" => 0, "t" => 0, "br" => 0, "rs" => 0, "r" => 0, "cs" => 0, "c" => 0, "blank" => 0}
              source.image_server_groups.each do |group|
                status = group.summary[:status][0]
                status = 'blank' if status.blank?
                images = group.number_of_images
                source_total[status] = source_total[status] + images
              end
              message_file.puts "#{chapman},#{place_name},#{church_name},#{register_name},#{source_name},#{source_total['u']},#{source_total['ar']},#{source_total['a']},#{source_total['ts']},#{source_total['t']},#{source_total['br']},#{source_total['rs']},#{source_total['r']},#{source_total['cs']},#{source_total['c']},#{source_total['blank']}"
              source_total.each_key { |key| register_total[key] = register_total[key] + source_total[key]}
            end
            source_name = ''
            message_file.puts "#{chapman},#{place_name},#{church_name},#{register_name},#{source_name},#{register_total['u']},#{register_total['ar']},#{register_total['a']},#{register_total['ts']},#{register_total['t']},#{register_total['br']},#{register_total['rs']},#{register_total['r']},#{register_total['cs']},#{register_total['c']},#{register_total['blank']}"
            register_total.each_key { |key| church_total[key] = church_total[key] + register_total[key]}
          end
          register_name = ''
          message_file.puts "#{chapman},#{place_name},#{church_name},#{register_name},#{source_name},#{church_total['u']},#{church_total['ar']},#{church_total['a']},#{church_total['ts']},#{church_total['t']},#{church_total['br']},#{church_total['rs']},#{church_total['r']},#{church_total['cs']},#{church_total['c']},#{church_total['blank']}"
          church_total.each_key { |key| place_total[key] = place_total[key] + church_total[key]}
        end
        place_total.each_key { |key| county_total[key] = county_total[key] + place_total[key]}
      end
      county_total.each_key { |key| grand_total[key] = grand_total[key] + county_total[key]}
    end
    # STATUS_ARRAY = ['u', 'ar', 'a', 'bt', 'ts', 't', 'br', 'rs', 'r', 'cs', 'c']
    message_file.close
  end

end
