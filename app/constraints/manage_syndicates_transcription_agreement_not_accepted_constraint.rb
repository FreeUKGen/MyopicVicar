class ManageSyndicatesTranscriptionAgreementNotAcceptedConstraint

  def self.matches?(request)
    request.query_parameters['option'] == 'Transcription Agreement Not Accepted'
  end
end
