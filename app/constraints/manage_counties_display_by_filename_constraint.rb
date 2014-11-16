class ManageCountiesDisplayByFilenameConstraint 
 
     def self.matches?(request)
      request.query_parameters['option'] == 'Review Batches by Filename'
     end
  end
 