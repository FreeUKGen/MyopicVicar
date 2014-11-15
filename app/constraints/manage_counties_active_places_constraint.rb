class ManageCountiesActivePlacesConstraint
 
     def self.matches?(request)
      request.query_parameters['option'] == 'Work with Active Places'
     end
  end
  