class  ManageCountiesUploadBatchConstraint  
 
     def self.matches?(request)
      request.query_parameters['option'] == 'Upload New Batch'
     end
  end
 