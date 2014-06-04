require 'chapman_code'

task :load_refinery_users => :environment do
#  load_syndicates
  load_counties
  load_users
end

# def load_syndicates
  # Syndicate.all.each_with_index do |syndicate, i|
    # Refinery::Syndicates::Syndicate.create(:name => syndicate.syndicate_code)
  # end  
# end
# 
def load_users
#  base_role = Refinery::Role.where(:title => 'Refinery').first
  
  UseridDetail.all.each do |detail|
    u = Refinery::User.new
    u.username = detail.userid
    u.email = detail.email_address
    u.password = 'Password'
    u.password_confirmation = 'Password'
    u.userid_detail_id = detail.id.to_s
    u.add_role("Refinery")
    
    unless u.save
#        binding.pry		 
    end
  end
end




