require 'chapman_code'

task :load_refinery_users => :environment do
  #
  Mongoid.load!("#{Rails.root}/config/mongoid.yml")
  load_users_from_mongo
end


def load_users_from_mongo
  p "Starting load"
  #  base_role = Refinery::Role.where(:title => 'Refinery').first
  #Refinery::Authentication::Devise::User.delete_all
  n = 0
  UseridDetail.all.each do |detail|
    u = User.where(:username => detail.userid).first
    if u.nil?
      u = User.new
      p "#{detail.userid} being added"
    end
    u.username = detail.userid
    u.email = detail.email_address
    u.password = 'Password' # no-op
    u.password_confirmation = 'Password' # no-op

    u.encrypted_password = detail.password # actual encrypted password
    u.userid_detail_id = detail.id.to_s
    u.add_role("Refinery")
    u.add_role('Superuser') if (detail.active && detail.person_role == 'technical')

    # binding.pry

    unless u.save
      print "Failed to save #{u.username} due to #{u.errors.messages}\n"
    end
    n = n + 1
  end
  p " #{n} records processed"
end
