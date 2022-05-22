desc 'list syndicate users information'
task list_transcriber_users_info: :environment do

  file_for_listing = 'log/list_transcriber_users_info.csv'
  FileUtils.mkdir_p(File.dirname(file_for_listing)) unless File.exist?(file_for_listing)
  file_for_listing = File.new(file_for_listing, 'w')
  p 'Started Listing of Transcriber Users Information'

  users = 0

  file_for_listing.puts 'Syndicate,Surname,Forename,Userid,Email Address,Date Signed Up,Email Address Last Confirmed,Latest VLD file,Latest CSV file'

  UseridDetail.where(active: true, person_role: 'transcriber').all.order_by(syndicate: 1, person_surname: 1, person_forename: 1).each do |user|
    #UseridDetail.where(active: true, person_surname: 'Vandervord',).all.order_by(syndicate: 1, person_surname: 1, person_forename: 1).each do |user| - Testing
    email_confirmed  = user.email_address_last_confirmned.present? ? user.email_address_last_confirmned.to_datetime.strftime('%d/%b/%Y') : ""
    syndicate = '"' + user.syndicate + '"'

    csv_display = 'None'

    FreecenCsvFile.where(userid_lower_case: user.userid_lower_case).or(FreecenCsvFile.where(transcriber_email: user.email_address)).all.order_by(updated_at: -1).each do |file|
      next if csv_display != 'None'

      csv_display = "#{file.chapman_code}(#{file.updated_at.to_datetime.strftime('%d/%b/%Y')})"
    end

    vld_display = 'None'
    Freecen1VldFile.where(userid: user.userid).or(Freecen1VldFile.where(transcriber_email_adress: user.email_address)).all.order_by(updated_at: -1).each do |file|
      next if vld_display != 'None'

      vld_display = "#{file.dir_name}(#{file.updated_at.to_datetime.strftime('%d/%b/%Y')})"
    end

    file_for_listing.puts "#{syndicate},#{user.person_surname},#{user.person_forename},#{user.userid},#{user.email_address},#{user.sign_up_date.to_datetime.strftime('%d/%b/%Y')},#{email_confirmed},#{vld_display},#{csv_display}"

    users += 1
  end

  p 'Finished Listing of Transcriber Users Information'
  p "Listed #{users} Transcriber Users - see log/list_transcriber_users_info.csv for output"
end
