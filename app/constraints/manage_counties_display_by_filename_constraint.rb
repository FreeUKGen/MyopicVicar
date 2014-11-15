class ManageCountiesDisplayByFilenameConstraint 
 
     def self.matches?(request)
      request.query_parameters['option'] == 'Review Batches listed by filename'
     end
  end
 