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
    "search_queries"
  ]

  def run_mongo(program, command_line)
    fq_program =  File.join(Rails.application.config.mongodb_bin_location, program)
    db = Mongoid.sessions[:default][:database]
    system "#{fq_program} --db #{db} #{command_line}\n"
    
  end
  
  def mysql_dbname
    db_config = Rails.application.config.database_configuration[Rails.env]
    
    db_config["database"]
  end
  
  def run_mysql(program, command_line)
    db_config = Rails.application.config.database_configuration[Rails.env]
    sql_user = db_config["username"]
    sql_password = db_config["password"]
    sql_database = db_config["database"]
    
    system "#{program} --user=#{sql_user} --password=#{sql_password} --database=#{sql_database} #{command_line}\n"    
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
      run_mysql('mysqldump', "#{mysql_dbname} #{table_name} > #{dumpfile}")
    end    

    MONGO_COLLECTIONS.each do |collection_name|
      run_mongo('mongodump', "--collection #{collection_name} --out #{working_dir}")
    end

    tarfile = File.join(Rails.application.config.backup_directory, 'files', "#{backup_stem}.taz")
    system("tar czf #{tarfile} #{working_dir}\n")
    system("rm -r #{working_dir}/*\n")
    # cd /home/apache/hosts/freereg2/MyopicVicar
    # rake build:freereg_from_files["2/3/4/5/8/9/10/11/12/13",,,]
    # tar czf /raid/freereg2/backups/files/$backup_stem.taz tmp/places.json tmp/churches.json tmp/registers.json tmp/freereg1_csv_files.json tmp/userid_details.json tmp/syndicates.json tmp/counties.json tmp/countries.json tmp/feedbacks.json tmp/search_queries.json $dumpfile*.dmp
    # rm $dumpfile*.dmp    
  end



  desc "Restore freereg database from backup file"
  task :restore_from_backup,[:backup_file, :datasets] => [:environment] do  |t,args|
    # check args against possible ones
  BACKUP_FILES = {
        "users" => {
          :json => ['syndicates', 'userid_details'],
          :sql  => ['refinery_users.dmp', 'refinery_roles.dmp', 'refinery_roles_users.dmp']
        },
        "pages" => {
          :sql => [
            'refinery_county_pages.dmp',
            'refinery_images.dmp',
            'refinery_page_parts.dmp',
            'refinery_page_part_translations.dmp',
            'refinery_pages.dmp',
            'refinery_page_translations.dmp',
            'refinery_resources.dmp'
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
        "queries" => {
          :json => ['search_queries']
        }
      }

    VALID_DATASETS = ["all"] + BACKUP_FILES.keys.map{|k| k.to_s}
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
    # check to make sure the database tables exist
    begin
      Refinery::User.count
    rescue
      print "Error: Database appears to be empty.  Run rake db:setup to create tables and seed it.\n"
      exit
    end
    # check emendations
    if EmendationRule.count == 0
      print "Error: Emendation rules have not been loaded.  Run rake load_emendations to load them.\n"
      exit
    end
    
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
    
    
    # all files should now be unzipped to extract_dir
    json_dir = File.join(extract_dir, 'tmp')
    sql_dir = File.join(extract_dir, 'raid', 'freereg2', 'backups', 'working')
    
    datasets.each do |dataset|
      files = BACKUP_FILES[dataset]
      if files[:json]
        files[:json].each do |collection|
          json_file = Dir.glob(File.join(json_dir, "*#{collection}.json")).first          
          run_mongo("mongoimport", "--collection #{collection} --file #{json_file}")
       end
      end
      if files[:sql]
        files[:sql].each do |sql_pattern|
          sql_file = Dir.glob(File.join(sql_dir, "*#{sql_pattern}")).first
          run_mysql("mysql", " < #{sql_file}")
        end
      end
    end

  end

end

