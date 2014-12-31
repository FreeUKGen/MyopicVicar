task :correct_syndicate_coordinators => :environment do
  #This task resets the coordinators and their roles based on the syndicate coordinators collection
  puts "Correcting Syndicate names for coordinators."
  file_for_warning_messages = "log/correct_syndicate_coordinators.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
  @@message_file = File.new(file_for_warning_messages, "w")
  Mongoid.load!("#{Rails.root}/config/mongoid.yml")

  UseridDetail.each do |syndicates|
    syndicates.syndicate_groups = Array.new
    syndicates.person_role = 'transcriber' if  syndicates.person_role == 'syndicate_coordinator'
    syndicates.save(:validate => false)
  end
  p 'emptied existing'
  Syndicate.each do |syndicate|
    code = syndicate.syndicate_code
    coordinator = syndicate.syndicate_coordinator
    coordinator_details = UseridDetail.where(:userid => coordinator).first
    unless coordinator_details.nil? || coordinator_details.syndicate_groups.nil?
      coordinator_details.syndicate_groups << code
      coordinator_details.person_role = 'syndicate_coordinator' if  coordinator_details.person_role == 'transcriber' || coordinator_details.person_role == 'researcher'
      coordinator_details.save(:validate => false)
      @@message_file.puts "added #{code} to #{coordinator_details.userid}"
    else
      @@message_file.puts "#{coordinator} has no document"
    end
  end
  Syndicate.each do |syndicate|
    coordinator = syndicate.syndicate_coordinator
    coordinator_details = UseridDetail.where(:userid => coordinator).first
    @@message_file.puts "#{coordinator_details}"
  end
end
