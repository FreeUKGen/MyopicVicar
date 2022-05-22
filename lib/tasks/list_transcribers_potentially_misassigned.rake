desc 'Get a list of transcribers potentially misassigned'
task list_transcribers_potentially_misassigned: :environment do

  file_for_listing = 'log/transcribers_potentially_misassigned.csv'
  FileUtils.mkdir_p(File.dirname(file_for_listing)) unless File.exist?(file_for_listing)
  file_for_listing = File.new(file_for_listing, 'w')
  p 'Started Listing of Transcribers Potentially Misassigned'

  users = 0

  problem_syndicates = ['Any County and Year', 'Any Questions? Ask Us', 'Technical', 'Wales Syndicate', 'Yorkshire Syndicate']

  valid_syndicates = Syndicate.all.pluck(:syndicate_code) - problem_syndicates

  file_for_listing.puts 'Syndicate,Surname,Forename,Userid,Email Address,Syndicate Coord,Date Signed Up,VLD files Chapman Codes,CSV files Chapman Codes'

  UseridDetail.where(active: true, person_role: 'transcriber').all.order_by(syndicate: 1, person_surname: 1, person_forename: 1).each do |user|
    if problem_syndicates.include?(user.syndicate) || valid_syndicates.exclude?(user.syndicate)

      csv_file_chapman_codes = SortedSet.new
      FreecenCsvFile.where(userid_lower_case: user.userid_lower_case).all.order_by(chapman_code: 1).each do |file|
        csv_file_chapman_codes << file.chapman_code
      end
      if csv_file_chapman_codes.size.zero?
        csv_display = 'None'
      else
        csv_display = ''
        csv_file_chapman_codes.each do |chap|
          csv_display += (chap + ' ')
        end
      end

      vld_file_chapman_codes = SortedSet.new
      Freecen1VldFile.where(userid: user.userid).all.order_by(dir_name: 1).each do |file|
        vld_file_chapman_codes << file.dir_name
      end
      if vld_file_chapman_codes.size.zero?
        vld_display = 'None'
      else
        vld_display = ''
        vld_file_chapman_codes.each do |chap|
          vld_display += (chap + ' ')
        end
      end

      file_for_listing.puts "#{user.syndicate},#{user.person_surname},#{user.person_forename},#{user.userid},#{user.email_address},#{user.syndicate_coordinator},#{user.sign_up_date.to_datetime.strftime('%d/%b/%Y %R')},#{vld_display},#{csv_display}"
      users += 1
    end
  end

  p 'Finished Listing of Transcribers Potentially Misassigned'
  p "Listed #{users} users - see log/transcribers_potentially_misassigned.csv for output"
end
