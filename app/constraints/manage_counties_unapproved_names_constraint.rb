class ManageCountiesUnapprovedNamesConstraint

  def self.matches?(request)
    request.query_parameters['option'] == 'Places with Unapproved Names'
  end
end

