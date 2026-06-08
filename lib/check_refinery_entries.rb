class CheckRefineryEntries
  include Mongoid::Document
  require 'userid_detail'
  def self.process(limit,fix)
    file_for_warning_messages = "log/check_refinery_entry_messages.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, "w")
    limit = limit.to_i

    puts "checking #{limit} documents for missing refinery entries "
    record_number = 0
    missing_records = 0
    process_records = 0
    UseridDetail.no_timeout.each do |userid|
      record_number = record_number + 1
      break if record_number == limit
      u = User.where(:username => userid.userid).first
      if u.nil?
        missing_records = missing_records + 1
        message_file.puts " #{userid.userid},missing"
        p " #{userid.userid},missing and added"
        password = Devise::Encryptable::Encryptors::Freereg.digest('temppasshope',nil,nil,nil)
        userid.password_confirmation = password if userid.password.nil?
        userid.password = password if userid.password.nil?
        userid.save_to_refinery if fix == "fix"
      end
    end
    puts "checked #{record_number} entries there were #{missing_records} missing Refinery entries"
    message_file.puts "checked #{record_number} entries there were #{missing_records} missing Refinery entries"
  end
end
