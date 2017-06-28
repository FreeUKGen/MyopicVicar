class UsersNeverUploadedFile
  attr_accessor :output_directory

  HEADER_ARRAY = ['USERID','SYNDICATE','EMAIL','ACTIVE','ACCOUNT_CREATION_DATE', 'EMAIL_ADDRESS_VALID']

  def initialize(output_directory = nil)
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
    list_user_info.where(number_of_files: 0)
  end

  def registered_before_six_months
    never_uploaded_file.where(:created_at.lt => 6.months.ago)
  end

  def list_user_info
    UseridDetail.only(:userid, :created_at, :number_of_files, :password, :syndicate, :email_address, :active)
  end

  def registered_users
    registered_user_lists = []
    registered_before_six_months.all.each do |user|
      next if technical_syndicate?user
      if user.password != registered_password
        registered_user_lists << HEADER_ARRAY.join(",")+"\n"
        registered_user_lists << user_information_for_display(user).join(",")+"\n"
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

  def user_information_for_display user
    [user.userid, pretty_syndicate_formatting(user),user.email_address, user.active,user.c_at.to_date, valid_email_domain(user)]
  end

  #Email Domain Verification
  def valid_email_domain user
    split_email = user.email_address.split('@')
    Resolv::DNS.open do |dns|
      @mail_servers = dns.getresources(split_email[1], Resolv::DNS::Resource::IN::MX)
    end
    @mail_servers.empty? ? false : true
  end

  def pretty_syndicate_formatting user
    user.syndicate.gsub(/[,]/,'-') unless user.syndicate.nil?
  end

  def technical_syndicate? user
    user.syndicate == "Technical"
  end

end