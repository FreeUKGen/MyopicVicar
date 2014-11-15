class ManageCountiesAscendingConstraint 
 
     def self.matches?(request)
      request.query_parameters['option'] ==  'Review Batches listed by ascending date'
     end
  end
 