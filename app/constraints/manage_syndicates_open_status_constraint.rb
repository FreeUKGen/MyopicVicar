class ManageSyndicatesOpenStatusConstraint

  def self.matches?(request)
    request.query_parameters['option'] == 'Review Open Status'
  end
end
