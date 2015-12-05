# load_freecen_users drops data in the collection and refinery tables before
# importing the users from the json and sql files specified as arguments
desc "Drop users in mongo and refinery and re-create from json,sql files"
task :load_freecen_users, [:in_json,:in_sql] => :environment do |t, args|
  if !args[:in_json].nil? && !args[:in_sql].nil? && \
      File.exists?(args[:in_json]) && File.exists?(args[:in_sql])
    dbname = Rails.configuration.database_configuration[Rails.env]["database"]
    dbuser = Rails.configuration.database_configuration[Rails.env]["username"]
    dbpw = Rails.configuration.database_configuration[Rails.env]["password"]

    puts "loading the refinery users and roles"
    puts "*** please enter the mysql password for the freecen2 user ***"
    cmd = "mysql -u #{dbuser} " + \
    "-p " + \
	  "#{dbname} < #{args[:in_sql]}"
    rv = `#{cmd}`
    puts rv

    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    db = Mongoid.sessions[:default][:database]
    puts "emptying the refinery_users table"
    UseridDetail.all.each do |detail|
      detail.delete #destroy would call callbacks, so just delete
    end

    puts "loading #{args[:in_json]} into database #{db} "
    cmd = Rails.application.config.mongodb_bin_location + \
          "mongoimport --db #{db} --collection userid_details " + \
          "--file #{args[:in_json]}"
    rv = `#{cmd}`
    puts rv
    
    puts "done."
  else
    if args[:in_json].nil? || !File.exists?(args[:in_json])
      puts "ERROR! could not find file '#{args[:in_json]}"
      puts 'usage: rake load_freecen_users["/path/in.json","/path/in.sql"]'
    else
      puts "ERROR! could not find file '#{args[:in_sql]}"
      puts 'usage: rake load_freecen_users["/path/in.json","/path/in.sql"]'
    end
  end
end

desc "Backup users in mongo and refinery to specified json,sql files"
task :save_freecen_users, [:out_json,:out_sql] => :environment do |t, args|
  if args[:out_json].nil?
    puts "ERROR! no out_json file specified."
    puts 'usage: rake save_freecen_users["/path/out.json","/path/out.sql"]'
  elsif args[:out_sql].nil?
    puts "ERROR! no out_sql file specified."
    puts 'usage: rake save_freecen_users["/path/out.json","/path/out.sql"]'
  else
    dbname = Rails.configuration.database_configuration[Rails.env]["database"]
    dbuser = Rails.configuration.database_configuration[Rails.env]["username"]
    dbpw = Rails.configuration.database_configuration[Rails.env]["password"]
    puts "saving refinery_users, refinery_roles_users, refinery_roles, and refinery_user_plugins sql"
    puts "*** please enter the mysql password for the freecen2 user ***"
    cmd = "mysqldump --opt -u #{dbuser} -p #{dbname} " + \
          "refinery_users refinery_roles refinery_roles_users " + \
	  "refinery_user_plugins > #{args[:out_sql]}"
    rv = `#{cmd}`
    puts rv

    puts "saving the mongo userid_details collection"
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    db = Mongoid.sessions[:default][:database]
    cmd = Rails.application.config.mongodb_bin_location + \
          "mongoexport --db #{db} --collection userid_details " + \
          "--out #{args[:out_json]}"
    rv = `#{cmd}`
    puts rv

  end
end

task :initialize_freecen_counties_and_coords => [:environment] do
  require 'chapman_code'
  sure=''
  STDOUT.puts "Are you SURE you want to reset counties and coordinators? (CENManager will become coord of all counties)\n(y/n)?"
  sure=STDIN.gets.chomp
  if 'y'==sure || 'Y'==sure
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    db = Mongoid.sessions[:default][:database]
    puts "emptying counties collection"
    County.all.each do |cty|
      cty.delete
    end
    puts "emptying countries collection"
    Country.all.each do |ctry|
      ctry.delete
    end
    puts "build counties from lib/chapman_code.rb, setting coord to CENManager"
    ChapmanCode::CODES.each do |cntry,codes|
      puts "country=#{cntry}"
      country_counties = []
      codes.each do |cname,ccode|
        puts "  county=#{cname} (#{ccode})"
        County.create(chapman_code: ccode, county_coordinator: "CENManager", county_coordinator_lower_case: "cenmanager", county_description: cname, county_notes: "")
	country_counties << ccode
      end
      Country.create(country_code: cntry, country_coordinator: "CENManager", counties_included: country_counties, country_coordinator_lower_case: "cenmanager")
    end
  else
    puts "Probably a wise choice."
  end
end

task :save_freecen_counties, [:out_json] => :environment do |t, args|
  if args[:out_json].nil?
    puts "ERROR! no out_json file specified."
    puts 'usage: rake save_freecen_counties["/path/out.json"]'
  else
    puts "saving the mongo counties collection"
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    db = Mongoid.sessions[:default][:database]
    cmd = Rails.application.config.mongodb_bin_location + \
          "mongoexport --db #{db} --collection counties " + \
          "--out #{args[:out_json]}"
    rv = `#{cmd}`
    puts rv
  end
end

task :load_freecen_counties, [:in_json] => :environment do |t, args|
  if !args[:in_json].nil? && File.exists?(args[:in_json])
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    db = Mongoid.sessions[:default][:database]
    puts "emptying the counties collection"
    Counties.all.each do |cty|
      cty.delete #destroy would call callbacks, so just delete
    end

    puts "loading #{args[:in_json]} into database #{db} "
    cmd = Rails.application.config.mongodb_bin_location + \
          "mongoimport --db #{db} --collection counties " + \
          "--file #{args[:in_json]}"
    rv = `#{cmd}`
    puts rv
    
    puts "done."
  else
    if args[:in_json].nil? || !File.exists?(args[:in_json])
      puts "ERROR! could not find file '#{args[:in_json]}"
      puts 'usage: rake load_freecen_users["/path/in.json","/path/in.sql"]'
    end
  end
end
