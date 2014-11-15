class  ManageCountiesReviewBatchConstraint  
 
     def self.matches?(request)
      request.query_parameters['option'] ==  'Review a specific Batch'
     end
  end
  