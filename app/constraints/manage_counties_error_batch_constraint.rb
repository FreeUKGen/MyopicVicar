class ManageCountiesErrorBatchConstraint
 
     def self.matches?(request)
      request.query_parameters['option'] == 'Review Batches with errors' 
     end
  end
 