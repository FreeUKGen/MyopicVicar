module ContactsHelper
  def do_we_show_keep_action?(contact)
    contact.keep.blank? && !contact.a_reply? ? do_we_permit = true : do_we_permit = false
    do_we_permit
  end

  def do_we_show_unkeep_action?(contact)
    contact.keep.present? && !contact.a_reply? ? do_we_permit = true :  do_we_permit = false
    do_we_permit
  end
end
