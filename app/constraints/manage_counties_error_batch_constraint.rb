class ManageCountiesErrorBatchConstraint
 
     def self.matches?(request)
      request.query_parameters['option'] == 'Review Batches with Errors' 
     end
  end
 