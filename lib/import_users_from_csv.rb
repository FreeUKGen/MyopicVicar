class ImportUsersFromCsv
  attr_accessor :file, :commit, :syndicate

  def initialize(file, commit, syndicate)
    @file = file
    @commit = commit
    @syndicate = syndicate
  end

  def import
    delete_file_if_exists("script/create_user.txt")
    existing_users, created_user, unsaved_user = [], [], []
    CSV.foreach(@file.path, headers: true) do |row|
      @userid = UseridDetail.new(row.to_hash)
      for_existing(existing_users, @userid) && next if user_existance(@userid.userid)
      @userid.add_fields(commit,syndicate)
      @userid.save
      @userid.save ? after_save(created_user,@userid) : failed_save(unsaved_user,@userid)
    end
    write_log_file("user_exists", existing_users) unless existing_users.empty?
    write_log_file("user_created", created_user) unless existing_users.empty?
    write_log_file("creation_failed", unsaved_user) unless existing_users.empty?
  end

  private

  def send_password_reset_mail userid
    fetch_refinery(userid).send_reset_password_instructions
  end

  def fetch_refinery userid
    Refinery::Authentication::Devise::User.where(:username => userid).first
  end

  def user_existance userid
    UseridDetail.where(userid: userid).present? && Refinery::Authentication::Devise::User.where(:username => userid).present?
  end

  def write_log_file(category, user_array)
    output = File.open( "script/create_user.txt","a+" )
    case
    when category == "user_exists"
      output << "Userid already existed: #{user_array.flatten} \n"
    when category == "user_created"
      output << "Userids created successfully: #{user_array.flatten} \n"
    when category == "creation_failed"
      output << "Userid creation failed: #{user_array.flatten} \n"
    else
      output << "Unknown reasons: #{user_array.flatten} \n"
    end
    output.close
  end

  def write_to_array array,value
    array << value
  end

  def after_save array,user
    send_password_reset_mail(user.userid)
    user.write_userid_file
    write_to_array(array,user.userid)
  end

  def failed_save array,user
    write_to_array(array,user.userid)
  end

  def for_existing(array,user)
    write_to_array(array,user.userid)
  end

  def flatten_array array
    array.collect(&:inspect).join(', ')
  end

  def delete_file_if_exists path_to_file
    File.delete(path_to_file) if File.exist?(path_to_file)
  end

end