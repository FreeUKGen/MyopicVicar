class CorrectImageServerGroup

  def self.process(len, fix)
    #The purpose of this clean up utility is to eliminate blank witness and duplicate witness entries in the database
    #to enable volume control we use the filenames as a means of selection
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    file_for_warning_messages = "log/image_server_group_count.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, "w")
    limit = len.to_i
    message_file.puts "Correcting #{limit} image server groups"
    p "Correcting #{limit} image server groups"
    process_image_server_group = 0
    ImageServerGroup.each do |group|
      process_image_server_group = process_image_server_group  + 1
      break if process_image_server_group == limit
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
          dups.each do |dup|
          p dup
          end
          dups.last.delete if fix.present?
          new_number_of_images_in_group = new_number_of_images_in_group - 1
        end
      end
      p "#{group.group_name},image number reduced from #{number_of_images_in_group} to #{new_number_of_images_in_group}" unless new_number_of_images_in_group == number_of_images_in_group
      group.update_attribute(:number_of_images, new_number_of_images_in_group) unless new_number_of_images_in_group == number_of_images_in_group
    end
    message_file.close
    p "Processed #{process_image_server_group} groups"
  end
end