module PhysicalFilesHelper

  def syndicate(physical)
    userid = physical.userid if physical.present?
    user = UseridDetail.userid(userid).first if userid.present?
    syndicate = user.syndicate if user.present?
  end

  def size(file)
    userid = file.userid if file.present?
    file_name = file.file_name if file.present?
    file_location =  File.join(Rails.application.config.datafiles, userid,file_name)
    if File.exists?(file_location)
      size = number_to_human_size(File.size(file_location))
    else
      size = nil
    end
    size
  end
end
