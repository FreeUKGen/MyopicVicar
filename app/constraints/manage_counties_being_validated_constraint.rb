class ManageCountiesBeingValidatedConstraint

  def self.matches?(request)
    request.query_parameters['option'] == 'Being Validated'
  end
end
