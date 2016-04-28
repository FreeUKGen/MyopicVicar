module CountiesHelper
  def email_address(coordinator)
    person = UseridDetail.where(:userid => coordinator).first
    email_address = person.email_address if person.present?
  end
end
