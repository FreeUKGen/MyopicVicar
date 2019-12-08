class  ManageCountiesOfflineReportsConstraint

  def self.matches?(request)
    request.query_parameters['option'] == 'Offline Reports'
  end
end
