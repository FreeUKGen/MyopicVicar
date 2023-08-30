desc "Remove secondary roles"
task :remove_secondary_roles => :environment do


  p "Remove secondary roles"
  ROLES_TO_REMOVE = ['master_county_coordinator']
  n = 0
  UseridDetail.all.no_timeout.each do |user|
    n = n + 1
    user.secondary_role = user.secondary_role - ROLES_TO_REMOVE
    user.save!
  end
  p "Processed #{n} secondary roles"
  p "finished"
end