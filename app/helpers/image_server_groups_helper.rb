module ImageServerGroupsHelper
  def do_we_offer_mail_to_cc(group) 
    send_email = false   
    if session[:manage_user_origin] == 'manage syndicate'
      if  !group.summary.nil? 
        if !group.nil? && !group.summary[:status].nil? && (group.summary[:status] - ['u','a','bt','ts','br','rs']).empty? == false
           send_email = true
        end 
      end 
    end
    send_email
  end
end
