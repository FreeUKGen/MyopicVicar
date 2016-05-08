class GetSoftwareVersion 
 
def self.process(process,time_start,time_end,version)
  if process == "manual"
    time_start_parts = time_start.split('/')
    time_end_parts = time_end.split('/')
    date_start = Time.new(time_start_parts[0],time_start_parts[1],time_start_parts[2])
    date_end = Time.new(time_end_parts[0],time_end_parts[1],time_end_parts[2])
  else
    control_record =  SoftwareVersion.control.first
    date_start = control_record.date_of_update
    date_end = Time.new
    last_version = control_record.version
    version = SoftwareVersion.update_version(last_version)
  end
  client = Octokit::Client.new(:login => Rails.application.config.github_user, :password => Rails.application.config.github_password)
  p " Start software version with start of #{date_start} and end of #{date_end} for version #{version}"
  response = client.commits_between("FreeUKGen/MyopicVicar",date_start,date_end)
  software_version = SoftwareVersion.new
  software_version.update_attributes(:date_of_update => date_end, :version => version, :type => "System")
   response.each do |commit|   
    commitment = Commitment.new
    commitment[:commitment_number] = commit[:sha]
    commitment[:author] = commit[:commit][:author][:name]
    commitment[:date_committed] = commit[:commit][:author][:date]
    commitment[:commitment_message] = commit[:commit][:message]
    software_version.commitments << commitment
    software_version.save
   end
   mods = ["app/models/search_record.rb", "app/models/emendation_rule.rb", "app/models/emendation_type.rb","lib/freereg1_translator.rb","lib/emendor.rb", "lib/tasks/load_emendations.rake"]  
   mods.each do |mod|
     response = client.commits_between("FreeUKGen/MyopicVicar", date_start, date_end, :path => mod)   
     response.each do |commit|
      commitment = Commitment.new
      commitment[:commitment_number] = commit[:sha]
      commitment[:author] = commit[:commit][:author][:name]
      commitment[:date_committed] = commit[:commit][:author][:date]
      commitment[:commitment_message] = commit[:commit][:message]
      software_version = SoftwareVersion.type("Search Record").date(commit[:commit][:author][:date]).first
      if software_version.present?
        p "existing "
        p mod
        software_version.commitments << commitment        
      else
        software_version = SoftwareVersion.new
        software_version.update_attributes(:date_of_update => commit[:commit][:author][:date], :version => commit[:commit][:author][:date], :type => "Search Record")
        software_version.commitments << commitment
      end
      software_version.save
     end
  end 
  control_record =  SoftwareVersion.control.first
  if control_record.blank?
    control_record = SoftwareVersion.new
    control_record.update_attribute(:type,"Control")
    control_record.save
  end
  last_system_update = SoftwareVersion.type("System").order_by(date_of_update: -1).first
  last_system_update_date = last_system_update.date_of_update
  last_system_update_version = last_system_update.version
  last_search_record_update = SoftwareVersion.type("Search Record").order_by(date_of_update: -1).first
  last_search_record_update_date = last_search_record_update.date_of_update
  control_record.update_attributes(:date_of_update =>last_system_update_date, :version => last_system_update_version, :last_search_record_version =>last_search_record_update_date) 
   p  control_record
end

 



  
  
end