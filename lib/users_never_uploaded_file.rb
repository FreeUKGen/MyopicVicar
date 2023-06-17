class UsersNeverUploadedFile
  attr_accessor :model_name, :output_directory, :process

  def initialize(model_name=nil, output_directory = nil, process=nil)
    @model_name = model_name
    @output_directory = output_directory
    @process = process
  end

  def lists
    delete_file_if_exists
    original_stdout = STDOUT.clone
    STDOUT.reopen(new_file, "w")
    puts uniq_userid_list
    STDOUT.reopen(original_stdout)
    puts "Total number of ids: #{uniq_userid_list.count}"
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
        registered_user_lists << user.userid
      end
    end
    registered_user_lists
  end

  def users_syndicate_any_county
    users_list = []
    model_name.in(syndicate: ["Any County and Year", "Any Questions Ask Us"]).each do |user|
      users_list << [user.userid, user.syndicate]
    end
    users_list
  end

  def registered_password
    Devise::Encryptable::Encryptors::Freereg.digest('temppasshope',nil,nil,nil)
  end

  def uniq_userid_list
    case @process
    when "users_never_uploaded_files"
      registered_users.uniq
    when "any_county_users"
      users_syndicate_any_county.uniq
    end
  end

  def valid_directory?
    File.directory?(output_directory_path)
  end

  # Create a new file named as current date and time
  def new_file
    raise "Not a Valid Directory" unless valid_directory?

    file_name = "#{Time.now.strftime("%Y%m%d%H%M%S")}_#{process}.txt"
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
    File.delete(*Dir.glob("#{output_directory_path}*_#{process}.txt"))
  end

end
