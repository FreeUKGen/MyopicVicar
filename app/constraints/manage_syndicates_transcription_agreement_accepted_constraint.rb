class ManageSyndicatesTranscriptionAgreementAcceptedConstraint

  def self.matches?(request)
    request.query_parameters['option'] == 'Transcription Agreement Accepted'
  end
end
