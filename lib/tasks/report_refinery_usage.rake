task :report_refinery_usage => :environment do
	p "User,Number,Last sign in"
  Refinery::User.all.each do |user|
  unless user.sign_in_count.nil? 
   	p "#{user.username},#{user.sign_in_count},#{user.last_sign_in_at}   "
   end
  end
end