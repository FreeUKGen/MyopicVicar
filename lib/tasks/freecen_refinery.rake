
desc "Backup freecen refinery pages to specified sql file"
task :save_freecen_refinery_pages, [:out_sql] => :environment do |t, args|
  if args[:out_sql].nil?
    puts "ERROR! no out_sql file specified."
    puts 'usage: rake save_freecen_refinery_pages["/path/out.sql"]'
  else
    dbname = Rails.configuration.database_configuration[Rails.env]["database"]
    dbuser = Rails.configuration.database_configuration[Rails.env]["username"]
    dbpw = Rails.configuration.database_configuration[Rails.env]["password"]

    puts "saving all of the refinery tables except the users and roles"
    puts "*** please enter the mysql password for the freecen2 user ***"
    cmd = "mysqldump --opt -u #{dbuser} -p #{dbname} " + \
     "--ignore-table=#{dbname}.refinery_authentication_devise_roles " + \
     "--ignore-table=#{dbname}.refinery_authentication_devise_roles_users " + \
     "--ignore-table=#{dbname}.refinery_authentication_devise_user_plugins " + \
     "--ignore-table=#{dbname}.refinery_authentication_devise_users" + \
     "> #{args[:out_sql]}"
    rv = `#{cmd}`
    puts rv
  end
end


# load_freecen_refinery_pages imports all refinery data except that related
# to users and user roles from the sql file specified as an argument
desc "Reload all refinery data (except users/roles) from sql file"
task :load_freecen_refinery_pages, [:in_sql] => :environment do |t, args|
  if !args[:in_sql].nil? && File.exists?(args[:in_sql])
    dbname = Rails.configuration.database_configuration[Rails.env]["database"]
    dbuser = Rails.configuration.database_configuration[Rails.env]["username"]
    dbpw = Rails.configuration.database_configuration[Rails.env]["password"]

    puts "loading the refinery sql (except users and roles)"
    puts "*** please enter the mysql password for the freecen2 user ***"
    cmd = "mysql -u #{dbuser} " + \
    "-p " + \
	  "#{dbname} < #{args[:in_sql]}"
    rv = `#{cmd}`
    puts rv

    puts "done."
  else
    puts "ERROR! could not find file '#{args[:in_sql]}"
    puts 'usage: rake load_freecen_refinery_pages["/path/in.sql"]'
  end
end
