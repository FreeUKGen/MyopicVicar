class ManageCountiesDescendingConstraint 
 
     def self.matches?(request)
      request.query_parameters['option'] ==  'Review Batches listed by descending date'
     end
  end
  