module ImageServerGroupsHelper
  def do_we_offer_mail_to_cc(group) 
    send_email = false   
    if !session[:county].present?
      if  !group.summary.nil? 
        if !group.nil? && !group.summary[:status].nil? && (group.summary[:status] - ['u','a','bt','br','rs']).empty? == false
           send_email = true
        end 
      end 
    end
    send_email
  end
end
