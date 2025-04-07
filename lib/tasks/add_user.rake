namespace :freeuk do

  desc 'Add fields to support statistics'
  task :add_user => [:environment] do
    # Print the time before start the process
    start_time = Time.now
    p "Starting at #{start_time}"
    number = 0
    UseridDetail.no_timeout.each do |user|
  		next if User.find_by(username: user.userid).present?
    	number  += 1
    	u = User.new(username: user.userid, email: user.email_address, encrypted_password: user.password, userid_detail_id: user.id)
    	u.save!
    end
    running_time = Time.now - start_time
    p "Added #{number} users"
  end
end
