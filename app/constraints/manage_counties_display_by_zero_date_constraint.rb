class ManageCountiesDisplayByZeroDateConstraint

  def self.matches?(request)
    request.query_parameters['option'] == 'Review Batches with Zero Dates'
  end
end
