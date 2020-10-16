class ManageCountiesIncorporatedConstraint

  def self.matches?(request)
    request.query_parameters['option'] == 'Incorporated'
  end
end
