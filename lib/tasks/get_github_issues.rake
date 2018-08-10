task :get_github_issues,[:repo]  => :environment do |t, args|
  #This task gets the issues for a repository
  file_for_warning_messages = "log/issues_#{args.repo}.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
  message_file = File.new(file_for_warning_messages, "w")
 
  client = Octokit::Client.new(:login => Rails.application.config.github_issues_login, :password => Rails.application.config.github_issues_password)
  message_file.puts "Gettting issues for #{args.repo}"
  status_options = ['ready','committed','in progress','need review','testing']
  client.auto_paginate = true
  issues = client.issues "FreeUKGen/#{args.repo}"
  p issues.length
  nature = 'feature' if args.repo == "MyopicVicar"
  nature = 'issue' if args.repo == "FreeUKRegProductIssues"

  issues.each do |issue|
    p issue if issue[:number] == 1471 || issue[:number] == 1452
    if issue[:state] == 'open'
      number =  issue[:number]
      title = issue[:title]
      if issue[:labels].present? 
        entries = issue[:labels].length
        if entries == 1
          status = issue[:labels][0][:name]
          if status_options.include?(status)
            state = status
            status = ''
          else
            state = 'incoming'
          end
        else
          status = Array.new
          state = 'incoming'
          issue[:labels].each do |label|
            if status_options.include?(label[:name])
              state = label[:name]
            else
              status << label[:name] unless status_options.include?(label[:name])
            end
          end
        end
      else
        status = ''
      end
      state = "product backlog" if state == 'ready'
      state = "sprint backlog" if state == 'committed'
      if issue[:assignees].present? 
        entries = issue[:assignees].length
        if entries == 1
          assignee = issue[:assignees][0][:login]
        else
          assignee = Array.new
          issue[:assignees].each do |label|
            assignee << label[:login]
          end
        end
      else
        assignee = ''
      end
      issue[:milestone].nil? ? milestone = '' : milestone = issue[:milestone][:title]
      comments = issue[:comments]
      created = issue[:created_at].strftime("%d/%m/%Y") 
      issue[:body].nil? ? description = '' : description = issue[:body]
      message_file.puts "#{nature}^#{number}^#{title}^#{status}^#{state}^#{assignee}^#{milestone}^#{comments}^#{created}"
      p "#{nature},#{number},#{title},#{status},#{state},#{assignee},#{milestone},#{comments},#{created}"
    end
  end
  #p "finished  #{n}"
end
