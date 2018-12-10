module FeedbacksHelper
  def do_we_show_keep_action?(feedback)
    feedback.keep.blank? && !feedback.a_reply? ? do_we_permit = true : do_we_permit = false
    do_we_permit
  end

  def do_we_show_unkeep_action?(message)
    feedback.keep.present? && !feedback.a_reply? ? do_we_permit = true :  do_we_permit = false
    do_we_permit
  end
end
