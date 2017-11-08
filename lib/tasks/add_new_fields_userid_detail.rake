namespace :freereg do
  desc "Add new fields to UseridDetail model"
  task :add_new_fields_userid_detail => [:environment] do |t, args|
    start_time = Time.now    
      p "Starting at #{start_time}"
      UseridDetail.collection.find().update_many(:$set => { :email_address_validity_change_message => []})
      p "Process finished"
      running_time = Time.now - start_time
      p "Running time #{running_time} "
    end
end





