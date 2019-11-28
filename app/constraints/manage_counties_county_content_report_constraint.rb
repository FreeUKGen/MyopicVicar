class  ManageCountiesCountyContentReportConstraint

  def self.matches?(request)
    request.query_parameters['option'] == 'County Content Report'
  end
end
