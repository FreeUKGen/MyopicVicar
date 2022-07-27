 namespace :freereg do

  SQL_TABLES = [
    "active_admin_comments",
    "refinery_county_pages",
    "refinery_images",
    "refinery_page_part_translations",
    "refinery_page_parts",
    "refinery_page_translations",
    "refinery_pages",
    "refinery_resources",
    "refinery_roles",
    "refinery_roles_users",
    "refinery_user_plugins",
    "refinery_users",
    "schema_migrations",
    "seo_meta"
  ]
  MONGO_COLLECTIONS = [
    "places",
    "churches",
    "registers",
    "freereg1_csv_files",
    "userid_details",
    "syndicates",
    "counties",
    "countries",
    "feedbacks",
    "search_statistics",
    "site_statistics"
  ]

  def run_mongo(program, command_line)
    fq_program =  File.join(Rails.application.config.mongodb_bin_location, program)
    db = Mongoid.clients[:default][:database]
    host = Mongoid.clients[:default][:hosts].first
    ssl = " --ssl "
    if Mongoid.clients[:default][:options] && Mongoid.clients[:default][:options][:ssl]
      ssl = " --ssl "
    else
      ssl = ""
    end
    cmd = "#{fq_program} #{ssl} --host #{host} --db #{db} #{command_line}"
    print "#{cmd}\n"
    system cmd

  end

  def mysql_dbname
    db_config = Rails.application.config.database_configuration[Rails.env]

    db_config["database"]
  end

  def run_mysql(program, command_line, suppress_db=false)
    db_config = Rails.application.config.database_configuration[Rails.env]
    sql_user = db_config["username"]
    sql_password = db_config["password"]
    sql_database = db_config["database"]

    if suppress_db
      cmd = "#{program} --user=#{sql_user} --password=#{sql_password}  #{command_line}"
    else
      cmd = "#{program} --user=#{sql_user} --password=#{sql_password} --database=#{sql_database} #{command_line}"
    end

    print "#{cmd}\n"
    system cmd
  end

  desc "Save freereg databases to a backup file"
  task :backup, [:backup_file] => [:environment] do  |t,args|
    # this needs to mimic this:
    # backup_stem=`date -u +"%Y%m%d%H%M%S"`
    backup_stem = Time.now.strftime("%Y%m%d%H%M%S")
    # dumpfile="/raid/freereg2/backups/working/$backup_stem"
    working_dir = File.join(Rails.application.config.backup_directory, 'working')
    # echo $dumpfile
    print "Backing up to #{working_dir}\n"

    SQL_TABLES.each do |table_name|
      dumpfile = File.join(working_dir, "#{table_name}.dmp")
      run_mysql('mysqldump', "#{mysql_dbname} #{table_name} > #{dumpfile}", true)
    end

    MONGO_COLLECTIONS.each do |collection_name|
      run_mongo('mongodump', "--collection #{collection_name} --out #{working_dir}")
    end

    tarfile = File.join(Rails.application.config.backup_directory, 'files', "#{backup_stem}.taz")
    tarcmd="tar czf #{tarfile} --directory #{working_dir} ."
    print "#{tarcmd}\n"
    system tarcmd
    rmcmd="rm -r #{working_dir}/*"
    print "#{rmcmd}\n"
    system "#{rmcmd}"
  end

  BACKUP_FILES = {
    "users" => {
      :json => ['syndicates', 'userid_details'],
      :sql  => ['refinery_users', 'refinery_roles', 'refinery_roles_users']
    },
    "pages" => {
      :sql => [
        'refinery_county_pages',
        'refinery_images',
        'refinery_page_parts',
        'refinery_page_part_translations',
        'refinery_pages',
        'refinery_page_translations',
        'refinery_resources'
      ]
    },
    "locations" => {
      :json => [
        'countries',
        'counties',
        'churches',
        'places',
        'registers'
      ]
    },
    "feedback" => {
      :json => ['feedbacks']
    },
    "statistics" => {
      :json => ['search_statistics', 'site_statistics']
    },
    "all" => {
      :json => MONGO_COLLECTIONS,
      :sql => SQL_TABLES
    }
  }
  VALID_DATASETS = BACKUP_FILES.keys.map{|k| k.to_s}

  def parse_args_for_datasets(args)
    unless args[:backup_file] && args[:datasets]
      print "Usage: rake restore_from_backup[backup_file,datasets]\n"
      print "\tbackup_file = path to location of .taz file containing automated F2 backups or directory extracted from .taz file.\n"
      print "\tdatasets = slash-delimited list of objects to restore\n"
      print "\t\tValid datasets are "+VALID_DATASETS.join(',')+"\n"
      exit
    end
    unless File.exist? args[:backup_file]
      print "Error: #{args[:backup_file]} is not a file.\n"
      exit
    end
    datasets = args[:datasets].split('/')
    bad_datasets = datasets - VALID_DATASETS
    unless bad_datasets.size == 0
      print "Error: #{bad_datasets.join(' and ')} are not valid datasets.\n"
      print "\tValid datasets are "+VALID_DATASETS.join('/')+"\n"
      exit
    end

    datasets
  end

  def validate_database
    # check to make sure the database tables exist
    begin
      Refinery::Authentication::Devise::User.count
    rescue
      print "Error: Database appears to be empty.  Run rake db:setup to create tables and seed it.\n"
      exit
    end
    # # check emendations
    # if EmendationRule.count == 0
    # print "Error: Emendation rules have not been loaded.  Run rake load_emendations to load them.\n"
    # exit
    # end

  end

  def extract_backup_dir(args)
    # unzip the file
    if Dir.exist? args[:backup_file]
      extract_dir = args[:backup_file]
    else
      restore_dir = File.join(Rails.root, 'tmp', 'restore')
      unless Dir.exist? restore_dir
        Dir.mkdir restore_dir
      end
      extract_dir = File.join(restore_dir, Process.pid.to_s)
      Dir.mkdir extract_dir

      # now untar the file
      system "tar xzf #{args[:backup_file]} --directory #{extract_dir}"
    end

    extract_dir
  end

  desc "Restore freereg database from backup file"
  task :restore,[:backup_file, :datasets] => [:environment] do  |t,args|
    datasets = parse_args_for_datasets(args)
    validate_database
    extract_dir = extract_backup_dir(args)

    # all files should now be unzipped to extract_dir

    json_dir = Dir.glob(File.join(extract_dir, '*')).find { |fn| File.directory?(fn) }

    sql_dir = File.join(extract_dir)

    datasets.each do |dataset|
      files = BACKUP_FILES[dataset]
      if files[:json]
        files[:json].each do |collection|
          json_file = Dir.glob(File.join(json_dir, "*#{collection}.bson")).first
          #          binding.pry
          run_mongo("mongorestore", "--drop --collection #{collection} #{json_file}")
        end
      end
      if files[:sql]
        files[:sql].each do |sql_pattern|
          sql_file = Dir.glob(File.join(sql_dir, "*#{sql_pattern}.dmp")).first
          #          binding.pry
          run_mysql("mysql", " < #{sql_file}")
        end
      end
    end

  end

end
