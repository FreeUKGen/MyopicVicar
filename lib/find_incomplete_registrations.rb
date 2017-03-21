class FindIncompleteRegistrations
	attr_accessor :user_details, :incompleted_registration_ids

	def initialize user_details=UseridDetail
		@user_details = user_details
		@incompleted_registration_ids = []
	end

	def system_administrator? current_user
		return false if current_user.nil?

		current_user.person_role == "system_administrator"
	end

	def list_incomplete_registrations
	   required_user_details.each { |user|
	   	next if registration_completed(user)
		  @incompleted_registration_ids << user.userid 
		 }
		@incompleted_registration_ids		
	end

	private

	def required_user_details
		 @user_details.only(:_id, :userid, :password)
	end

	def registration_completed user
		user.password != registered_password
	end

	def registered_password
		Devise::Encryptable::Encryptors::Freereg.digest('temppasshope',nil,nil,nil)
	end
end