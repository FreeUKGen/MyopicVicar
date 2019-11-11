module CountiesHelper
  def email_address(coordinator)
    person = UseridDetail.where(userid: coordinator).first
    email_address = person.email_address if person.present?
  end

  def county_coordinator_agreement(coordinator)
    person = UseridDetail.where(userid: coordinator).first
    if person.present?
      status = person.new_transcription_agreement
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
    else
      result = 'U'
    end
    result
  end

end
