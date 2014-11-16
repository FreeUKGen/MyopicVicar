class ManageCountiesDescendingConstraint 
 
     def self.matches?(request)
      request.query_parameters['option'] ==  'Review Batches by Most Recent Date of Change'
     end
  end
  