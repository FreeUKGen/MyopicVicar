require 'chapman_code'

task :load_refinery => :environment do
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


def load_counties
  position = 1
  ChapmanCode::CODES.each_pair do |name, code|
    Refinery::CountyPages::CountyPage.create( :name => name, :chapman_code => code, :position => position )
    position = position+1
  end
end
