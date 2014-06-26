require 'chapman_code'

task :load_refinery => :environment do
#  load_syndicates
#  load_counties
  load_users_from_mongo
end

# def load_syndicates
  # Syndicate.all.each_with_index do |syndicate, i|
    # Refinery::Syndicates::Syndicate.create(:name => syndicate.syndicate_code)
  # end  
# end
# 
def load_users_from_mongo
#  base_role = Refinery::Role.where(:title => 'Refinery').first
  Refinery::User.delete_all
  
  UseridDetail.all.each do |detail|
    
    u = Refinery::User.new
    u.username = detail.userid
    u.email = detail.email_address
    u.password = 'Password'                # no-op
    u.password_confirmation = 'Password'   # no-op

    u.encrypted_password = detail.password # actual encrypted password
    u.userid_detail_id = detail.id.to_s
    u.add_role("Refinery")

#    binding.pry  

    unless u.save
      print "Failed to save #{u.username} due to #{u.errors.messages}\n"
    end
  end
end


def load_counties
  position = 1
  ChapmanCode::CODES.each_pair do |name, code|
    Refinery::CountyPages::CountyPage.create( :name => name, :chapman_code => code, :position => position )
    position = position+1
  end
end
