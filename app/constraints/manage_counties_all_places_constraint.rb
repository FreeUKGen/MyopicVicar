class ManageCountiesAllPlacesConstraint
 
     def self.matches?(request)
      request.query_parameters['option'] == 'Work with All Places'
     end
  end
  