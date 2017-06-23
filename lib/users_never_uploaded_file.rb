class UsersNeverUploadedFile
  attr_accessor :model_name, :output_directory

  HEADER_ARRAY = ['USERID','SYNDICATE','EMAIL','ACTIVE','ACCOUNT_CREATION_DATE', 'EMAIL_ADDRESS_VALID']

  def initialize(model_name=nil, output_directory = nil)
    @model_name = model_name
    @output_directory = output_directory
  end

  def lists
    delete_file_if_exists
    original_stdout = STDOUT.clone
    STDOUT.reopen(new_file, "w")
    puts uniq_userid_list
    STDOUT.reopen(original_stdout)
    puts "Total number of ids: #{uniq_userid_list.count - 1}"
  end

  private

  def never_uploaded_file
    UseridDetail.where(number_of_files: 0)
  end

  def registered_before_six_months
    never_uploaded_file.where(:created_at.lt => 6.months.ago)
  end

  def registered_users
    registered_user_lists = []
    registered_before_six_months.all.each do |user|
      if user.password != registered_password
        registered_user_lists << HEADER_ARRAY.join(";")+"\n"
        registered_user_lists << user_information(user).join(";")+"\n"
      end
    end
    registered_user_lists
  end

  def registered_password
    Devise::Encryptable::Encryptors::Freereg.digest('temppasshope',nil,nil,nil)
  end

  def uniq_userid_list
    registered_users.uniq
  end

  def valid_directory?
    File.directory?(output_directory_path)
  end

  # Create a new file named as current date and time
  def new_file
    raise "Not a Valid Directory" unless valid_directory?

    file_name = "#{Time.now.strftime("%Y%m%d%H%M%S")}_users_never_uploaded_file.csv"
    "#{output_directory_path}#{file_name}"
  end

  # Set an output directory
  # If there is no ouput directory, then set the default
  # else check the trailing slash at the end of the directory
  def output_directory_path
    if @output_directory.nil?
      directory = File.join(Rails.root, 'script')
    else
      directory = File.join(@output_directory, "")
    end
    directory
  end

  def delete_file_if_exists
    File.delete(*Dir.glob("#{output_directory_path}*_users_never_uploaded_file.csv"))
  end

  def user_information user
    [user.userid, user.syndicate,user.email_address, user.active,user.c_at.to_date, user_email_address_valid(user)]
  end

  def user_email_address_valid user
    user.email_address_last_confirmned != nil
  end

end