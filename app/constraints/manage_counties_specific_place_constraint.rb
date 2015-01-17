class ManageCountiesSpecificPlaceConstraint

  def self.matches?(request)
    request.query_parameters['option'] == 'Work with Specific Place'
  end
end

