module PhysicalFilesHelper

 def syndicate(physical)
  p physical
  userid = physical.userid if physical.present?
  user = UseridDetail.userid(userid).first if userid.present?
  syndicate = user.syndicate if user.present?
   
 end
end
