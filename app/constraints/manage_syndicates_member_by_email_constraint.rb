class ManageSyndicatesMemberByEmailConstraint
 
     def self.matches?(request)
      request.query_parameters['option'] ==  'Select Specific Member by Email Address'
     end
  end
 

  