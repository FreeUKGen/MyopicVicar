module UseridDetailsHelper
  def registered(userid)
    userid.password == Devise::Encryptable::Encryptors::Freereg.digest('temppasshope',nil,nil,nil) ? registered = "No" : registered = "Yes"
    registered
  end

  def active_user(status)
    result = 'Yes' if status
    result = 'No' unless status
    result
  end

  def agreement(status)
    case status
    when 'Accepted'
      result = 'A'
    when 'Unknown'
      result = 'U'
    when 'Declined'
      result = 'D'
    when 'Pending'
      result = 'P'
    end
    result
  end
end
