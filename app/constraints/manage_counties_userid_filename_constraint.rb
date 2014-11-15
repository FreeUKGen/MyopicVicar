class ManageCountiesUseridFilenameConstraint
 
     def self.matches?(request)
      request.query_parameters['option'] ==  'Review Batches listed by userid then filename'
     end
  end
 