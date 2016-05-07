class GetSoftwareVersion 
 
def self.process(time_start,time_end,version)
  p "Initial set up"
  p time_start
  p time_end
  p version
  time_start_parts = time_start.split('/')
  time_end_parts = time_end.split('/')
  client = Octokit::Client.new(:login => Rails.application.config.github_user, :password => Rails.application.config.github_password)
  date_start = Time.utc(time_start_parts[0],time_start_parts[1],time_start_parts[2],time_start_parts[3],time_start_parts[4],time_start_parts[5])
  date_end = Time.utc(time_end_parts[0],time_end_parts[1],time_end_parts[2],time_end_parts[3],time_end_parts[4],time_end_parts[5])
  p " Start #{date_start} End #{date_end} for version #{version}"
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
     p mod
     response = client.commits_between("FreeUKGen/MyopicVicar", date_start, date_end, :path => mod)   
     response.each do |commit|
      commitment = Commitment.new
      commitment[:commitment_number] = commit[:sha]
      commitment[:author] = commit[:commit][:author][:name]
      commitment[:date_committed] = commit[:commit][:author][:date]
      commitment[:commitment_message] = commit[:commit][:message]
      software_version = SoftwareVersion.type("Search Record").date(commit[:commit][:author][:date]).first
      if software_version.present?
        p "adding to existing"
        p mod
        p commitment[:date_committed] = commit[:commit][:author][:date]
        software_version.commitments << commitment
        
      else
        software_version = SoftwareVersion.new
        software_version.update_attributes(:date_of_update => commit[:commit][:author][:date], :version => commit[:commit][:author][:date], :type => "Search Record")
        software_version.commitments << commitment
      end
      software_version.save
     end
  end
   
   
   
   #p response
end

 



  
  
end