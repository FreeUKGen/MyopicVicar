class GetSoftwareVersion
  require 'app'

  # sudo -u webserv bundle exec rake RAILS_ENV=production foo:get_software_version[automatic,2016/1/1,2016/3/1,1.4.1]
  def self.process(process, time_start, time_end, version)
    server = SoftwareVersion.extract_server(Socket.gethostname)
    appln = App.name_downcase
    if process == 'manual'
      time_start_parts = time_start.split('/')
      time_end_parts = time_end.split('/')
      date_start = Time.new(time_start_parts[0], time_start_parts[1], time_start_parts[2])
      date_end = Time.new(time_end_parts[0], time_end_parts[1], time_end_parts[2])
      new_version = version
      control_record = SoftwareVersion.create(server: server, app: appln, date_of_update: date_end, version: version, type: 'Control')
    else
      control_record = SoftwareVersion.server(server).app(appln).control.order_by(date_of_update: -1).first
      if control_record.present?
        date_start = control_record.date_of_update
        date_end = Time.new
        last_version = control_record.version
        new_version = SoftwareVersion.update_version(last_version)
        last_search_record_version = control_record.last_search_record_version
      else
        date_start = Time.new(2019, 6, 1)
        date_end = Time.new
        new_version = '1.5.0'
        last_search_record_version = '1.5.0'
        control_record = SoftwareVersion.create(server: server, app: appln, date_of_update: date_end, version: new_version, type: 'Control')
      end
    end

    # Create system record with commitments
    client = Octokit::Client.new(login: Rails.application.config.github_issues_login, password: Rails.application.config.github_issues_password)
    p " Start software version with start of #{date_start} and end of #{date_end} for version #{new_version}"
    response = client.commits_between('FreeUKGen/MyopicVicar', date_start, date_end)
    if response.present?
      software_version = SoftwareVersion.create(server: server, app: appln, date_of_update: date_end, version: new_version, type: 'System')
      response.each do |commit|
        commitment = Commitment.new
        commitment[:commitment_number] = commit[:sha]
        commitment[:author] = commit[:commit][:author][:name]
        commitment[:date_committed] = commit[:commit][:author][:date]
        commitment[:commitment_message] = commit[:commit][:message]
        software_version.commitments << commitment
      end
      software_version.save

      # create search record
      search_record_version = SoftwareVersion.server(server).app(appln).search_record.order_by(date_of_update: -1).first
      last_search_record_version = search_record_version.blank? ? new_version : search_record_version.version

      # add commitments to search record
      mods = ['app/models/search_record.rb', 'app/models/emendation_rule.rb', 'app/models/emendation_type.rb','lib/freereg1_translator.rb','lib/emendor.rb', 'lib/tasks/load_emendations.rake']
      all_responses = []
      mods.each do |mod|
        responses = client.commits_between('FreeUKGen/MyopicVicar', date_start, date_end, path: mod)
        all_responses << responses if responses.present?
      end
      if all_responses.present?
        search_record_version = SoftwareVersion.create(server: server, app: appln, date_of_update: date_end, version: new_version, type: 'Search Record')
        last_search_record_version = new_version
        all_responses.each do |mod|
          mod.each do |commit|
            commitment = Commitment.new
            commitment[:commitment_number] = commit[:sha]
            commitment[:author] = commit[:commit][:author][:name]
            commitment[:date_committed] = commit[:commit][:author][:date]
            commitment[:commitment_message] = commit[:commit][:message]
            search_record_version.commitments << commitment
          end
        end
      end
      search_record_version.save

      # update control record
      control_record.update_attributes(version: new_version, last_search_record_version: last_search_record_version, date_of_update: date_end )
    end
    p control_record
  end
end
