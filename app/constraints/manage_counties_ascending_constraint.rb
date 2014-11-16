class ManageCountiesAscendingConstraint 
 
     def self.matches?(request)
      request.query_parameters['option'] ==  'Review Batches by Oldest Date of Change'
     end
  end
 