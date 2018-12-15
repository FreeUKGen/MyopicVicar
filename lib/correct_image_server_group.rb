class CorrectImageServerGroup

  def self.process(len, fix)
    #The purpose of this clean up utility is to eliminate blank witness and duplicate witness entries in the database
    #to enable volume control we use the filenames as a means of selection
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    file_for_warning_messages = "log/image_server_group_count.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, "w")
    limits = len.split('/')
    p limits
    if limits.length == 1
      limit = len.to_i
      message_file.puts "Correcting #{limit} image server groups"
      p "Correcting #{limit} image server groups"
      process_image_server_group = 0
      ImageServerGroup.no_timeout.each do |group|
        p "image group #{group.id}"
        process_image_server_group = process_image_server_group  + 1
        p process_image_server_group if (process_image_server_group/100)*100 == process_image_server_group
        break if process_image_server_group == limit
        core_deletion(group, message_file, fix)
      end
    else
      p    "#{limits[1]}"
      groupid = limits[1]
      p groupid
      group = ImageServerGroup.where(id: groupid).first
      if group.present?
        process_image_server_group = process_image_server_group + 1
        core_deletion(group, message_file)
      else
        p "Image server group #{groupid} does not exist"
      end
    end
    message_file.close
    p "Processed #{process_image_server_group} groups"
  end

  def self.core_deletion(group, message_file, fix)
    p "core deletion #{group.id}"
    group_images = ImageServerImage.image_server_group_id(group.id).all
    number_of_images_in_group = group_images.length
    new_number_of_images_in_group = number_of_images_in_group
    group_images.each do |image|
      dups = ImageServerImage.where(image_server_group_id: group.id, image_file_name: image.image_file_name)
      number = dups.count
      if number >= 2
        number = number - 1
        message_file.puts "#{group.group_name},#{image.image_file_name},#{number}"
        p "#{group.group_name},#{image.image_file_name},#{number} duplicates"
        dups[1].delete if fix.present?
        new_number_of_images_in_group = new_number_of_images_in_group - 1 if fix.present?
      end
    end
    p "#{group.group_name},image number reduced from #{number_of_images_in_group} to #{new_number_of_images_in_group}" unless new_number_of_images_in_group == number_of_images_in_group
    group.update_attribute(:number_of_images, new_number_of_images_in_group) if !(new_number_of_images_in_group == number_of_images_in_group) || fix.present?

  end
end
