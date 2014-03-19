require 'chapman_code'

task :load_refinery => :environment do
#  load_users
#  load_syndicates
  load_counties
end

# def load_syndicates
  # Syndicate.all.each_with_index do |syndicate, i|
    # Refinery::Syndicates::Syndicate.create(:name => syndicate.syndicate_code)
  # end  
# end
# 
# def load_users
  # UseridDetail.all.each do |detail|
    # u = Refinery::User.new
    # u.username = detail.userid
    # u.email = detail.email_address
    # u.password = 'Password'
    # u.password_confirmation = 'Password'
    # u.save
  # end
# end


def load_counties
  position = 1
  ChapmanCode::CODES.each_pair do |name, code|
    Refinery::Counties::County.create( :county => name, :chapman_code => code, :position => position )
    position = position+1
  end
end