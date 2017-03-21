class IncompleteRegistration
  attr_accessor :user_details, :incompleted_registration_users

  def initialize user_details=UseridDetail
    @user_details = user_details
    @incompleted_registration_users = []
  end

  def list_users
    required_user_details.each { |user|
      next if registration_completed(user)
      @incompleted_registration_users << user
    }
    @incompleted_registration_users
  end

  private

  def required_user_details
    @user_details.only(:_id, :userid, :password, :email_address, )
  end

  def registration_completed user
    user.password != registered_password
  end

  def registered_password
    Devise::Encryptable::Encryptors::Freereg.digest('temppasshope',nil,nil,nil)
  end
end