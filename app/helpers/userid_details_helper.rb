module UseridDetailsHelper
  def registered(userid)
    userid.password == Devise::Encryptable::Encryptors::Freereg.digest('temppasshope',nil,nil,nil) ? registered = "No" : registered = "Yes"
    registered
  end
end
