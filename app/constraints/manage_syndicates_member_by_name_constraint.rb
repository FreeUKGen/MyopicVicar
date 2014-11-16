class ManageSyndicatesMemberByNameConstraint
 
     def self.matches?(request)
      request.query_parameters['option'] ==   'Select Specific Member by Surname/Forename'
     end
  end
 
 
  