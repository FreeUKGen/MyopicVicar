class GetSoftwareVersion
  require 'app'
  require 'date'

  # sudo -u webserv bundle exec rake RAILS_ENV=production foo:get_software_version[automatic,2016/1/1,2016/3/1,1.4.1]
  def self.process(process, time_start, time_end, version)
    server = SoftwareVersion.extract_server(Socket.gethostname)
    appln = App.name_downcase
    if process == 'manual'
      time_start_parts = time_start.split('/')
      time_end_parts = time_end.split('/')
      date_start = DateTime.new(time_start_parts[0].to_i, time_start_parts[1].to_i, time_start_parts[2].to_i)
      date_end = DateTime.new(time_end_parts[0].to_i, time_end_parts[1].to_i, time_end_parts[2].to_i)
      new_version = version
      control_record = SoftwareVersion.create(server: server, app: appln, date_of_update: date_end, version: version, type: 'Control')
    else
      # ie automatic
      control_record = SoftwareVersion.server(server).app(appln).control.order_by(date_of_update: -1).first
      if control_record.present?
        # normal
        date_start = control_record.date_of_update + 1
        date_end = DateTime.now
        last_version = control_record.version
        new_version = SoftwareVersion.update_version(last_version)
        last_search_record_version = control_record.last_search_record_version
      else
        # initialization
        date_start = DateTime.new(2019, 6, 1)
        date_end = DateTime.now
        new_version = '1.5.0'
        last_search_record_version = '1.5.0'
        control_record = SoftwareVersion.create(server: server, app: appln, date_of_update: date_end, version: new_version, type: 'Control')
      end
    end
    date_range = []
    date_range << date_start
    date_index = date_start + 1
    while date_index <= date_end
      date_range << date_index
      date_index = date_index + 1
    end
    p " Start software version with start of #{date_start} and end of #{date_end} for version #{new_version}"
    client = Octokit::Client.new(access_token: Rails.application.config.github_issues_access_token)
    software_version = SoftwareVersion.create(server: server, app: appln, date_of_update: date_end, version: new_version, type: 'System')
    search_record_version = SoftwareVersion.server(server).app(appln).search_record.order_by(date_of_update: -1).first
    last_search_record_version = search_record_version.blank? ? new_version : search_record_version.version
    # mods are the search record changes that indicate a change in the way a search record is computed
    mods = ['app/models/search_record.rb', 'app/models/emendation_rule.rb', 'app/models/emendation_type.rb', 'lib/freereg1_translator.rb', 'lib/emendor.rb', 'lib/tasks/load_emendations.rake']
    search_record_version = SoftwareVersion.create(server: server, app: appln, date_of_update: date_end, version: new_version, type: 'Search Record')
    save_version = false
    save_search_version = false

    date_range.each do |date|
      # deal with all commitments
      response = client.commits_on('FreeUKGen/MyopicVicar', date)
      if response.present?
        response.each do |commit|
          commitment = Commitment.new
          commitment[:commitment_number] = commit[:sha]
          commitment[:author] = commit[:commit][:author][:name]
          commitment[:date_committed] = commit[:commit][:author][:date]
          commitment[:commitment_message] = commit[:commit][:message]
          software_version.commitments << commitment
          save_version = true
        end
      end
      # deal with only search record commitments
      all_responses = []
      mods.each do |mod|
        responses = client.commits_on('FreeUKGen/MyopicVicar', date, path: mod)
        all_responses << responses if responses.present?
      end
      if all_responses.present?
        last_search_record_version = new_version
        all_responses.each do |mod|
          mod.each do |commit|
            commitment = Commitment.new
            commitment[:commitment_number] = commit[:sha]
            commitment[:author] = commit[:commit][:author][:name]
            commitment[:date_committed] = commit[:commit][:author][:date]
            commitment[:commitment_message] = commit[:commit][:message]
            search_record_version.commitments << commitment
            save_search_version = true
          end
        end
      end
    end
    software_version.destroy unless save_version
    search_record_version.destroy unless save_search_version
    control_record.update_attributes(version: new_version, last_search_record_version: last_search_record_version, date_of_update: date_end)
    p control_record
  end
end
