class ManageCountiesUseridFilenameConstraint
 
     def self.matches?(request)
      request.query_parameters['option'] ==  'Review Batches by Userid then Filename'
     end
  end
 