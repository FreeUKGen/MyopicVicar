class ManageSyndicatesMemberByUseridConstraint
 
     def self.matches?(request)
      request.query_parameters['option'] ==  'Select Specific Member by Userid'
     end
  end
 
  